# Azure Site-2-Site (S2S) VPN

An Azure VPN gateway is made up of these elements:

* Virtual network gateway
* Local network gateway
* Connection
* Gateway subnet

# Azure Point-2-Site (P2S) VPN

#### Point-to-site VPN can use one of the following protocols:

* **OpenVPN® Protocol**, an SSL/TLS based VPN protocol. A TLS VPN solution can penetrate firewalls, since most firewalls open TCP port 443 outbound, which TLS uses. OpenVPN can be used to connect from Android, iOS (versions 11.0 and above), Windows, Linux, and Mac devices (macOS versions 10.13 and above).
* **Secure Socket Tunneling Protocol (SSTP)**, a proprietary TLS-based VPN protocol. A TLS VPN solution can penetrate firewalls, since most firewalls open TCP port 443 outbound, which TLS uses. SSTP is only supported on Windows devices. Azure supports all versions of Windows that have SSTP (Windows 7 and later).
* **IKEv2 VPN**, a standards-based IPsec VPN solution. IKEv2 VPN can be used to connect from Mac devices (macOS versions 10.11 and above).

#### Point-to-site authentication methods

* Authenticate using native **Azure certificate authentication**.<p>
When using the native Azure certificate authentication, a **client certificate on the device** is used to authenticate the connecting user. *The root certificate is required for the validation and must be uploaded to Azure.*

* Authenticate using native **Azure Active Directory authentication**.<p>
It **requires a RADIUS server** that integrates with the AD server. During authentication, the Azure VPN Gateway passes authentication messages back and forth between the RADIUS server and the connecting device.<br>
**The RADIUS server can also integrate with AD certificate services.** This lets you use the RADIUS server and your enterprise certificate deployment for P2S certificate authentication as an alternative to the Azure certificate authentication. Integrating the RADIUS server with AD certificate services means that you can do all your certificate management in AD, *you don’t need to upload root certificates and revoked certificates to Azure*.


