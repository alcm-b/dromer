MAKEFLAGS = -s
include ref
URLLIST := url.list
TS := $(shell date +%Y-%m-%d_%H%M)
.PHONY = usage extract transform load html
## make extract
## 1 retrieve raw HTML from the site
extract:
	mkdir -p data/$(TS)
	$(RANDSLEEP)
	while read a ; do \
		$(RANDSLEEP) ; \
		b=`echo "$$a" | tr -s -c 'a-zA-Z0-9.' '_'` ;\
		probe=data/$(TS)/$${b}`date +%Y-%m-%d_%H%M`.html ;\
		curl -m 15 -f "$$a" > $$probe 2> data/$(TS)/curl.err; \
		grep -o '"http[^"]\+page[^"]\+"' $$probe | tr -d '"' >> data/$(TS)/secondary.list; \
	done < $(URLLIST)  ;
	sort data/$(TS)/secondary.list | uniq > data/$(TS)/$(URLLIST)
	while read a ; do \
		$(RANDSLEEP) ; \
		b=`echo "$$a" | tr -s -c 'a-zA-Z0-9.' '_'` ;\
		datafile=data/$(TS)/$${b}`date +%Y-%m-%d_%H%M`.html ;\
		curl -m 15 -f "$$a" > $$datafile 2>> data/$(TS)/curl.err ; \
	done < data/$(TS)/$(URLLIST) ;
	cd data && rm -f current && ln -s `readlink -f $(TS)` current

## make transform
## convert raw HTML to tab-delimited list
transform: data/current/$(TS).txt

data/current/$(TS).txt: html
	for i in data/current/*html ; do $(MAKE) $$i.xml.list ; done | sort | uniq >> $@
	cd data/current && rm -f ad_records.txt && ln -s `readlink -f $(TS).txt` ad_records.txt

html:
	# cp data/current/*html test/current

data/current/%.xml.list: data/current/%.xml
	 xpath -q -e  '//td[@class="f14"]|//span[@class="f14"]|//center/nobr/a/@href|//center/nobr/a/text()' $< \
		 | tr '\n' '\t' \
		 | sed -e 's/[[:space:]]\+href/\nhref/g; $$ s/\(.\)$$/\1\n/; s/<[^>]\+>//g' | tee $@

data/current/%.xml: data/current/%
	 sed 's#<br.?/># #g;' $< \
		| iconv -f CP1251 -t us-ascii//TRANSLIT \
		| tidy -numeric -asxml --wrap 0 --output-xml yes 2>tmp/tidy.err \
		> $@ ; exit 0

## 3 prepare data for loadning into Google Fusion table
load: data/current/$(TS).csv

data/current/$(TS).csv: year = $(shell date +'%Y')
data/current/$(TS).csv:
	awk -F '\t' '\
		/^[[:space:]]\+$$/ { next }; \
		{ OFS=","; gsub(/[^0-9]/, "", $$5); \
			gsub(/^href=/, "", $$1); \
			print "$(year)-"$$2, $$1,"\""$$3"\"", $$4, $$5; \
		}'\
	< data/current/ad_records.txt \
	> data/current/$(TS).csv
