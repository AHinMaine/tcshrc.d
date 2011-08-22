
TCSHDIR = $(HOME)/.tcshrc.d

all:
	@echo ; echo ; echo "Options:" ; \
		echo ; \
		echo ; \
		echo "make install-home    - Install the tcsh config from the current directory into the current user's home directory" ; \
		echo ; \
		echo "make install-etcskel - Install the tcsh config from the current directory into the current system's /etc/skel directory." ; \
		echo ; \
		echo "make dist            - Run the tcshrc distribution script to ssh copy your tcsh config to remote hosts" ; \
		echo ; \
		echo "make perldoc         - Generate the perldoc list for accurate completions when using the perldoc command" ; \
		echo ; echo ; echo

install-home:
	mkdir $(TCSHDIR) ;								\
	cp -r -t $(TCSHDIR) 							\
								Alias				\
								Complete			\
								Env					\
								Keys				\
								Paths				\
								Prompts				\
								Set					\
								bin					\
								etc					\
								opt					\
								Makefile			\
								tcshrc ;			\
	cp -r -t $(HOME) .home/.tcshrc

install-etcskel:
	@if [ -w "/etc/skel" ] ; then 					\
		mkdir /etc/skel/.tcshrc.d ;					\
		cp -r -t /etc/skel/.tcshrc.d 				\
								Alias				\
								Complete			\
								Env					\
								Keys				\
								Paths				\
								Prompts				\
								Set					\
								bin					\
								etc					\
								opt					\
								.home				\
								Makefile			\
								tcshrc &&			\
		cp -r -t /etc/skel .home/.tcshrc ;			\
	else											\
		echo "Must run as root..." ;				\
	fi

dist:
	@bin/tcshrc.dist.sh

perldoc: pod

pod:
	@bin/podlist.pl


