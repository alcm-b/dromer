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
		curl -m 15 -f "$$a" > $$datafile 2> data/$(TS)/curl.err ; \
	done < data/$(TS)/$(URLLIST) ;
	cd data && rm -f current && ln -s `readlink -f $(TS)` current

## 2 convert data
# select: file = test/sample1.utf-8.html 
# select:
# 	 iconv -f utf-8 -t us-ascii//TRANSLIT $(file) \
# 		| tidy -raw -asxml --wrap 0 --output-xml yes 2>/dev/null \
# 		| sed 's/&nbsp;/ /g; s#<br.?/># #g; s/[\xA0\x14\&]//g; ' \
# 		# > $(file).xml
# 	 xpath -q -e  '//td[@class="f14"]/text()|//span[@class="f14"]/text()|//center/nobr/a/@href|//center/nobr/a/text()' $(file).xml
# 	# | xmllint - --format \
# 
# # try 1: with per-directory pattern rules
# xml1: test/$(TS)_xml
# 
# test/$(TS)_html:
# 	mkdir $@
# 	cp sample.utf8.html $@
# 
# test/$(TS)_xml: test/$(TS)_html
# 	mkdir $@
# 	$(MAKE) $@/sample.utf8.html.xml
# 
# test/$(TS)_xml/%.xml: test/$(TS)_html/%
# 	 iconv -f utf-8 -t us-ascii//TRANSLIT $< \
# 		| tidy -raw -asxml --wrap 0 --output-xml yes 2>/dev/null \
# 		| sed 's/&nbsp;/ /g; s#<br.?/># #g; s/[\xA0\x14\&]//g; ' \
# 		> $@
# 
# # try 2: with single directory of intermediate results
# xml2: test/$(TS)
# 
# test/$(TS):
# 	mkdir $@
# 	cp sample.utf8.html $@
# 	$(MAKE) $@/sample.utf8.html.xml
# 
# test/$(TS)/%.xml: test/$(TS)/%
# 	 iconv -f utf-8 -t us-ascii//TRANSLIT $< \
# 		| tidy -raw -asxml --wrap 0 --output-xml yes 2>/dev/null \
# 		| sed 's/&nbsp;/ /g; s#<br.?/># #g; s/[\xA0\x14\&]//g; ' \
# 		> $@
# 	 
# try 3: with hard-coded directory of intermediate results
# xml3: test/$(TS)_result3
# init:
# 	mv test/current test/$(TS)
# 	mkdir test/current 
# 
# html3: init
# 	$(MAKE) test/current/sample.utf8.html
# 
# test/$(TS)_result3: html3
# 	$(MAKE) test/current/sample.utf8.html.xml
# 	touch $@
# 
# test/current/%.html:
# 	cp sample.utf8.html test/current
# 
data/current/%.xml: data/current/%
	 sed 's#<br.?/># #g;' $< \
		| iconv -f CP1251 -t us-ascii//TRANSLIT \
		| tidy -numeric -asxml --wrap 0 --output-xml yes 2>tmp/tidy.err \
		> $@ ; exit 0
 
# try 4: separate fetch from transform and make them async
transform: data/current/$(TS).csv

data/current/$(TS).csv: html
	for i in data/current/*html ; do $(MAKE) $$i.xml.list ; done | sort | uniq >> $@
	cd data/current && rm -f ad_records.csv && ln -s `readlink -f $(TS).csv` ad_records.csv

html:
	# cp data/current/*html test/current

data/current/%.xml.list: data/current/%.xml
	 xpath -q -e  '//td[@class="f14"]|//span[@class="f14"]|//center/nobr/a/@href|//center/nobr/a/text()' $< \
		 | tr '\n' '\t' \
		 | sed -e 's/[[:space:]]\+href/\nhref/g; $$ s/\(.\)$$/\1\n/; s/<[^>]\+>//g'

## 3 load to Fusion table
load:
	# cat test/2013-04-15_0952_result | awk -F '\t' ' /^[[:space:]]/ { next }; { OFS=","; gsub(/[^0-9]/, "", $5); gsub(/^href=/, "", $1); print "2013-"$2, $1,"\""$3"\"", $4, $5;}' > test/2013-04-15_0952_result.csv
