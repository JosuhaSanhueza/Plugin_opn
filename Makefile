# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# FreeBSD Ports / OPNsense Plugin Manifest
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

PORTNAME=	gamecontrol
PORTVERSION=	1.0
CATEGORIES=	sysutils
MASTER_SITES=	# none
DISTFILES=	# none

MAINTAINER=	josuha@opnsense.local
COMMENT=	Control modular DNS de juegos por host/estudiante (Unbound/DNSBL)

LICENSE=	BSD2CLAUSE

PLUGIN_NAME=		gamecontrol
PLUGIN_VERSION=		1.0
PLUGIN_COMMENT=		Control modular DNS de juegos por host/estudiante (Unbound/DNSBL)
PLUGIN_MAINTAINER=	josuha@opnsense.local
PLUGIN_TIER=		2
PLUGIN_REQUIRES=	python3

.include "../../Mk/plugins.mk"
