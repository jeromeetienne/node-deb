# full operation: make src_delete src_import ppa_upload

# define variables
# - to get the codename => $ lsb_release -c -s
PKGNAME="nodejs"
VERSION="0.4.2"
CODENAME="maverick"

PWD	:= $(shell pwd)
TMP_DIR	:= $(PWD)/tmp
SRC_DIR	:= $(TMP_DIR)/node
SRC_GIT	:= https://github.com/joyent/node.git
SRC_TAG	:= v$(VERSION)

all: build

mydistclean: src_delete deb_clean

#################################################################################
#		node src handling						#
#################################################################################

src_import:
	mkdir -p $(SRC_DIR)
	(cd $(TMP_DIR) && git clone $(SRC_GIT))
	(cd $(SRC_DIR) && git checkout $(SRC_TAG))

src_delete:
	rm -rf $(SRC_DIR)

#################################################################################
#		classic targets (use by dpkg)					#
#################################################################################

clean:
	(cd $(SRC_DIR) && make clean; true)

build:
	(cd $(SRC_DIR) && export GCC_VERSION=44 && ./configure && make)

install:
	(cd $(SRC_DIR) && make install)

#################################################################################
#		deb package handling						#
#################################################################################

deb_base_build:
	cp -a debian-base debian
	for i in debian/*; do sed -i s/lucid/$(CODENAME)/g $$i; done

deb_src_build:
	debuild -S -k'jerome etienne' -I.git

deb_bin_build:
	debuild -i -us -uc -b

deb_upd_changelog:
	dch --newversion $(VERSION)~$(CODENAME)1~ppa`date +%Y%m%d%H%M` --maintmaint --force-bad-version --distribution `lsb_release -c -s` Another build

deb_clean:
	rm -fr ./debian
	rm -f ../$(PKGNAME)_$(VERSION)~$(CODENAME)1~ppa*

ppa_upload: src_delete src_import clean deb_clean deb_base_build deb_upd_changelog deb_src_build
	dput -U ppa:jerome-etienne/neoip ../$(PKGNAME)_$(VERSION)~$(CODENAME)1~ppa*_source.changes 
