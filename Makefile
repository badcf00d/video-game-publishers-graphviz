SHELL = bash
GRAPH := publishers.png
DOT_FILES := $(wildcard *.dot)
HIRES_PNG := $(shell find images/hires -type f -name '*.png')
PNG_MIN := $(subst /hires,,$(HIRES_PNG))
PNG_OPT := $(HIRES_PNG:%.png=%.png.opt)
DATE_STRING := $(shell date -u +"%F-%T-UTC")
GIT_STRING := $(shell git describe --always --dirty)
GENERATE_STRING := $(shell printf "%s (%s)" $(DATE_STRING) $(GIT_STRING))

HEADER := <\
<TABLE CELLPADDING="10" BORDER="0" CELLSPACING="0">\
	<TR><TD ALIGN="right">\
		<FONT POINT-SIZE="64">The Video Game Publisher Graph</FONT><BR ALIGN="RIGHT"/>\
		<FONT POINT-SIZE="26">Generated on $(GENERATE_STRING)</FONT><BR ALIGN="RIGHT"/>\
		<FONT POINT-SIZE="26">Hosted at github.com/badcf00d</FONT><BR ALIGN="RIGHT"/><BR ALIGN="RIGHT"/>\
		<FONT POINT-SIZE="12">Disclaimer: Trademarks are used under fair use for informational and editorial purposes, this work is not affiliated with any of the entities featured within it.</FONT><BR ALIGN="RIGHT"/>\
	</TD></TR>\
</TABLE>\
>

.PHONY: graph hires images clean release checks
graph: $(GRAPH)
hires: $(PNG_OPT)
images: $(PNG_MIN)

$(GRAPH): $(DOT_FILES) $(PNG_MIN)
	$(info Making graph $(GENERATE_STRING): $(notdir $@))
	@dot $(DOT_FILES) |\
		gvpack -m25 -Glayout="neato" -Glabeljust="r" -Gfontname="Fira Sans UltraLight" -Glabel="{HEADER}" |\
		perl -p -e 's/"{HEADER}"/$(subst /,\/,${HEADER})/' |\
		neato -s -n2 -Tpng -o $@

release: $(GRAPH)
	@optipng -zc9 -zm8 -zs0 -f0 -clobber -strip all $<

%.png.opt: %.png
	$(info Optipng: $(notdir $<))
	@mogrify +profile "*" -fuzz 1% -trim +repage -flatten -background none -resize 1024x1024\> $<
	@optipng -o4 -clobber -silent -strip all $<

images/%.png: images/hires/%.png
	$(info Resizing: $(notdir $<))
	@convert $< -resize 6000@ $@

clean:
	@rm -f $(PNG_MIN) $(GRAPH)

checks:
	@diff -s -a -y --color=always --suppress-common-lines \
		<(find ./images/hires/ -type f -printf "%f\n" -iname "*.png" | sort) --label "PNG files" \
		<(grep -o -P "[\w\d]*.png" publishers.dot | sort) --label "Files mentioned in graph"
