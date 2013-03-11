TS := $(shell date +%Y-%m-%d_%H%M)
RANDSLEEP = sleep `perl -e 'print int(rand(39));'`
get:
	mkdir -p data/$(TS)
	$(RANDSLEEP)
	while read a ; do \
		$(RANDSLEEP) ; \
		b=`echo "$$a" | tr -s -c 'a-zA-Z0-9.' '_'` ;\
		probe=data/$(TS)/$${b}`date +%Y-%m-%d_%H%M`.html ;\
		curl -m 15 -f "$$a" > $$probe 2> data/$(TS)/curl.err; \
		grep -o '"http[^"]\+page[^"]\+"' $$probe | tr -d '"' >> data/$(TS)/secondary.list; \
	done < url.list ;
	sort data/$(TS)/secondary.list | uniq > data/$(TS)/url.list  
	while read a ; do \
		$(RANDSLEEP) ; \
		b=`echo "$$a" | tr -s -c 'a-zA-Z0-9.' '_'` ;\
		datafile=data/$(TS)/$${b}`date +%Y-%m-%d_%H%M`.html ;\
		curl -m 15 -f "$$a" > $$datafile 2> data/$(TS)/curl.err ; \
	done < data/$(TS)/url.list ;
