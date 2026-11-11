// Which addresses of this machine can a phone or tablet on the same network reach?
import os from 'node:os';

/**
 * How likely an address is the one a phone on the same Wi-Fi can reach (lower is
 * better): home/office ranges first, virtual adapters (Docker, VMs, VPNs) and
 * self-assigned addresses last.
 */
export function lanScore(address, name = '') {
  let score = 3;
  if (address.startsWith('192.168.')) score = 0;
  else if (address.startsWith('10.')) score = 1;
  else if (/^172\.(1[6-9]|2\d|3[01])\./.test(address)) score = 2;
  else if (address.startsWith('169.254.')) score = 9;
  if (/docker|veth|^br-|virbr|vmnet|vbox|vethernet|wsl|utun|tun\d|tap\d|tailscale|zt|wg\d/i.test(name)) score += 5;
  return score;
}

/**
 * Can another device possibly reach this address? Not the documentation/test ranges that
 * containers and cloud sandboxes hand out (192.0.2.x, 198.51.100.x, 203.0.113.x), nor the
 * benchmarking range 198.18.0.0/15.
 */
export function reachable(address) {
  return !/^(192\.0\.2\.|198\.51\.100\.|203\.0\.113\.|198\.1[89]\.|0\.|127\.)/.test(address);
}

/** IPv4 addresses of this machine on the local network, most likely Wi-Fi/Ethernet address first. */
export function lanAddresses(interfaces = os.networkInterfaces()) {
  const out = [];
  for (const [name, list] of Object.entries(interfaces)) {
    for (const net of list || []) {
      if ((net.family === 'IPv4' || net.family === 4) && !net.internal && reachable(net.address)) out.push({ address: net.address, score: lanScore(net.address, name) });
    }
  }
  return out.sort((a, b) => a.score - b.score).map((entry) => entry.address);
}
