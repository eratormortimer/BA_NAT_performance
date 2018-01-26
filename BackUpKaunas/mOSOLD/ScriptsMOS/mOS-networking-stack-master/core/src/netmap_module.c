/* for io_module_func def'ns */
#include "io_module.h"
/* for mtcp related def'ns */
#include "mtcp.h"
/* for errno */
#include <errno.h>
/* for logging */
#include "debug.h"
/* for num_devices_* */
#include "config.h"
/* for netmap definitions */
#define NETMAP_WITH_LIBS
#include "netmap_user.h"
/* for poll */
#include <sys/poll.h>
/* for NBBY */
#include <sys/param.h>
/*----------------------------------------------------------------------------*/
#define MAX_PKT_BURST			64
#define ETHERNET_FRAME_SIZE		1514
#define MAX_IFNAMELEN			(IF_NAMESIZE + 10)
#define EXTRA_BUFS			512
#define IDLE_POLL_WAIT			1 /* msecs */
#define IDLE_POLL_COUNT			10
//#define CONST_POLLING			1
/*----------------------------------------------------------------------------*/

struct netmap_private_context {
	struct nm_desc *local_nmd[MAX_DEVICES];
	unsigned char snd_pktbuf[MAX_DEVICES][ETHERNET_FRAME_SIZE];
	unsigned char *rcv_pktbuf[MAX_PKT_BURST];
	uint16_t rcv_pkt_len[MAX_PKT_BURST];
	uint16_t snd_pkt_size[MAX_DEVICES];
	uint8_t dev_poll_flag[MAX_DEVICES];
	uint8_t idle_poll_count; 
} __attribute__((aligned(__WORDSIZE)));
/*----------------------------------------------------------------------------*/
void
netmap_init_handle(struct mtcp_thread_context *ctxt)
{
	struct netmap_private_context *npc;
	char ifname[MAX_IFNAMELEN];
	char nifname[MAX_IFNAMELEN];
	struct netdev_entry **ent;
	int j;

	ent = g_config.mos->netdev_table->ent;
	/* create and initialize private I/O module context */
	ctxt->io_private_context = calloc(1, sizeof(struct netmap_private_context));
	if (ctxt->io_private_context == NULL) {
		TRACE_ERROR("Failed to initialize ctxt->io_private_context: "
			    "Can't allocate memory\n");
		exit(EXIT_FAILURE);
	}
	
	npc = (struct netmap_private_context *)ctxt->io_private_context;

	/* initialize per-thread netmap interfaces  */
	for (j = 0; j < g_config.mos->netdev_table->num; j++) {
#if 0
		if (if_indextoname(devices_attached[j], ifname) == NULL) {
			TRACE_ERROR("Failed to initialize interface %s with ifidx: %d - "
				    "error string: %s\n",
				    ifname, devices_attached[j], strerror(errno));
			exit(EXIT_FAILURE);
		}
#else
		strcpy(ifname, ent[j]->dev_name);
#endif
		if (unlikely(g_config.mos->num_cores == 1))
			sprintf(nifname, "netmap:%s", ifname);
		else
			sprintf(nifname, "netmap:%s-%d", ifname, ctxt->cpu);
		
		TRACE_INFO("Opening %s with j: %d (cpu: %d)\n", nifname, j, ctxt->cpu);

		struct nmreq base_nmd;
		memset(&base_nmd, 0, sizeof(base_nmd));
		base_nmd.nr_arg3 = EXTRA_BUFS;

		npc->local_nmd[j] = nm_open(nifname, &base_nmd, 0, NULL);
		if (npc->local_nmd[j] == NULL) {
			TRACE_ERROR("Unable to open %s: %s\n",
				    nifname, strerror(errno));
			exit(EXIT_FAILURE);
		}
	}
}
/*----------------------------------------------------------------------------*/
int
netmap_link_devices(struct mtcp_thread_context *ctxt)
{
	/* linking takes place during mtcp_init() */
	
	return 0;
}
/*----------------------------------------------------------------------------*/
void
netmap_release_pkt(struct mtcp_thread_context *ctxt, int ifidx, unsigned char *pkt_data, int len)
{
	/* 
	 * do nothing over here - memory reclamation
	 * will take place in dpdk_recv_pkts 
	 */
}
/*----------------------------------------------------------------------------*/
int
netmap_send_pkts(struct mtcp_thread_context *ctxt, int nif)
{
	int pkt_size, idx;
	struct netmap_private_context *npc;
	mtcp_manager_t mtcp;

	npc = (struct netmap_private_context *)ctxt->io_private_context;
	idx = nif;
	pkt_size = npc->snd_pkt_size[idx];
	mtcp = ctxt->mtcp_manager;

	/* assert-type statement */
	if (pkt_size == 0) return 0;

#ifdef NETSTAT
	mtcp->nstat.tx_packets[nif]++;
	mtcp->nstat.tx_bytes[nif] += pkt_size + ETHER_OVR;
#endif
	
 tx_again:
	if (nm_inject(npc->local_nmd[idx], npc->snd_pktbuf[idx], pkt_size) == 0) {
		TRACE_DBG("Failed to send pkt of size %d on interface: %d\n",
			  pkt_size, idx);

		ioctl(npc->local_nmd[idx]->fd, NIOCTXSYNC, NULL);
		goto tx_again;
	}
	
#ifdef NETSTAT
	//	mtcp->nstat.rx_errors[idx]++;
#endif
	npc->snd_pkt_size[idx] = 0;
	
	return 1;
}
/*----------------------------------------------------------------------------*/
uint8_t *
netmap_get_wptr(struct mtcp_thread_context *ctxt, int nif, uint16_t pktsize)
{
	struct netmap_private_context *npc;
	int idx = nif;

	npc = (struct netmap_private_context *)ctxt->io_private_context;
	if (npc->snd_pkt_size[idx] != 0)
		netmap_send_pkts(ctxt, nif);

	npc->snd_pkt_size[idx] = pktsize;
	
	return (uint8_t *)npc->snd_pktbuf[idx];
}
/*----------------------------------------------------------------------------*/
int32_t
netmap_recv_pkts(struct mtcp_thread_context *ctxt, int ifidx)
{
	struct netmap_private_context *npc;
	struct nm_desc *d;
	npc = (struct netmap_private_context *)ctxt->io_private_context;
	d = npc->local_nmd[ifidx];

	int p = 0;
	int c, got = 0, ri = d->cur_rx_ring;
	int n = d->last_rx_ring - d->first_rx_ring + 1;
	int cnt = MAX_PKT_BURST;



	for (c = 0; c < n && cnt != got && npc->dev_poll_flag[ifidx]; c++) {
		/* compute current ring to use */
		struct netmap_ring *ring;
		
		ri = d->cur_rx_ring + c;
		if (ri > d->last_rx_ring)
			ri = d->first_rx_ring;
		ring = NETMAP_RXRING(d->nifp, ri);
		for ( ; !nm_ring_empty(ring) && cnt != got; got++) {
			u_int i = ring->cur;
			u_int idx = ring->slot[i].buf_idx;
			npc->rcv_pktbuf[p] = (u_char *)NETMAP_BUF(ring, idx);
			npc->rcv_pkt_len[p] = ring->slot[i].len;
			p++;
			ring->head = ring->cur = nm_ring_next(ring, i);
		}
	}
	d->cur_rx_ring = ri;

	npc->dev_poll_flag[ifidx] = 0;

	return p;
}
/*----------------------------------------------------------------------------*/
uint8_t *
netmap_get_rptr(struct mtcp_thread_context *ctxt, int ifidx, int index, uint16_t *len)
{
	struct netmap_private_context *npc;
	npc = (struct netmap_private_context *)ctxt->io_private_context;

	*len = npc->rcv_pkt_len[index];
	return (unsigned char *)npc->rcv_pktbuf[index];
}
/*----------------------------------------------------------------------------*/
int32_t
netmap_select(struct mtcp_thread_context *ctxt)
{
	int i, rc;
	struct pollfd pfd[MAX_DEVICES];
	struct netmap_private_context *npc = 
		(struct netmap_private_context *)ctxt->io_private_context;
	
	/* see if num_devices have been registered */
	if (npc->local_nmd[0] == NULL)
		return -1;

	for (i = 0; i < g_config.mos->netdev_table->num; i++) {
		pfd[i].fd = npc->local_nmd[i]->fd;
		pfd[i].events = POLLIN;
	}

#ifndef CONST_POLLING	
	if (npc->idle_poll_count >= IDLE_POLL_COUNT) {
		rc = poll(pfd, g_config.mos->netdev_table->num, IDLE_POLL_WAIT);
	} else
#endif
		{
			rc = poll(pfd, g_config.mos->netdev_table->num, 0);
		}

	npc->idle_poll_count = (rc == 0) ? (npc->idle_poll_count + 1) : 0;

	for (i = 0; rc > 0 && i < g_config.mos->netdev_table->num; i++)
		if (!(pfd[i].revents & (POLLERR)))
			npc->dev_poll_flag[i] = 1;
	return 0;
}
/*----------------------------------------------------------------------------*/
int
netmap_get_nif(struct ifreq *ifr)
{
	int i;
	struct netdev_entry **ent = g_config.mos->netdev_table->ent;

	for (i = 0; i < g_config.mos->netdev_table->num; i++)
		if (!strcmp(ifr->ifr_name, ent[i]->dev_name))
			return i;

	return -1;
}
/*----------------------------------------------------------------------------*/
int32_t
netmap_dev_ioctl(struct mtcp_thread_context *ctx, int nif, int cmd, void *argp)
{
	/* unimplemented */
	return -1;
}
/*----------------------------------------------------------------------------*/
void
netmap_destroy_handle(struct mtcp_thread_context *ctxt)
{
	int i;
	struct netmap_private_context *npc;

	npc = (struct netmap_private_context *)ctxt->io_private_context;

	for (i = 0; i < g_config.mos->netdev_table->num; i++)
		close(npc->local_nmd[i]->fd);
}
/*----------------------------------------------------------------------------*/
void
netmap_load_module_upper_half(void)
{
	int i;
	int num_dev;
	uint64_t cpu_mask;
	int queue_range;
	
	num_dev = g_config.mos->netdev_table->num;
	
	for (i = 0; i < num_dev; i++) {
		cpu_mask = g_config.mos->netdev_table->ent[i]->cpu_mask;
		queue_range = sizeof(cpu_mask) * NBBY - __builtin_clzll(cpu_mask);
		num_queues =  (num_queues < queue_range) ? 
			queue_range : num_queues;
	}
}
/*----------------------------------------------------------------------------*/
static void
set_promisc(char *ifname)
{
	int fd, ret;
	struct ifreq eth;

	fd = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
	if (fd == -1) {
		TRACE_ERROR("Couldn't open socket!\n");
		return;
	}
	strcpy(eth.ifr_name, ifname);
	ret = ioctl(fd, SIOCGIFFLAGS, &eth);
	if (ret == -1) {
		TRACE_ERROR("Get ioctl for %s failed!\n",
			    ifname);
		close(fd);
		return;
	}

	if (eth.ifr_flags & IFF_PROMISC) {
		TRACE_ERROR("Interface %s is already set to "
			    "promiscuous mode\n", ifname);
		close(fd);
		return;
	}
	eth.ifr_flags |= IFF_PROMISC;

	ret = ioctl(fd, SIOCSIFFLAGS, &eth);
	if (ret == -1) {
		TRACE_ERROR("Set ioctl failed for %s\n", ifname);
		close(fd);
		return;
	}

	close(fd);
	
}
/*----------------------------------------------------------------------------*/
void
netmap_load_module_lower_half(void)
{
	struct netdev_entry **ent;
	int j;

	ent = g_config.mos->netdev_table->ent;
	
	for (j = 0; j < g_config.mos->netdev_table->num; j++) {
		set_promisc(ent[j]->dev_name);		
	}
}
/*----------------------------------------------------------------------------*/
io_module_func netmap_module_func = {
	.load_module_upper_half	   = netmap_load_module_upper_half,
	.load_module_lower_half	   = netmap_load_module_lower_half,
	.init_handle		   = netmap_init_handle,
	.link_devices		   = netmap_link_devices,
	.release_pkt		   = netmap_release_pkt,
	.send_pkts		   = netmap_send_pkts,
	.get_wptr   		   = netmap_get_wptr,
	.set_wptr		   = NULL,
	.recv_pkts		   = netmap_recv_pkts,
	.get_rptr	   	   = netmap_get_rptr,
	.get_nif		   = netmap_get_nif,
	.select			   = netmap_select,
	.destroy_handle		   = netmap_destroy_handle,
	.dev_ioctl		   = netmap_dev_ioctl,
};
/*----------------------------------------------------------------------------*/
