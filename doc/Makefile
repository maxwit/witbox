#
# http://www.maxwit.com
#

DESTDIR = release

#BOOK_TEX := $(wildcard *.tex)
#BOOK_TEX := $(filter-out style.tex $(BOOK_TEX)))
BOOK_TEX := user_manual.tex
BOOK_DVI := $(BOOK_TEX:%.tex=%.dvi)
BOOK_PDF := $(BOOK_TEX:%.tex=%.pdf)

ART_TEX := $(wildcard *.art.tex)
ART_PDF := $(ART_TEX:%.tex=%.pdf)

#all: $(BOOK_PDF) $(ART_PDF) ${SLI_PDF}
all: $(BOOK_PDF)
	@echo
	@ls -lh $(BOOK_PDF)
	@echo

%.pdf: %.tex $(ART_TEX)
	latex $<
	latex $<
	dvipdfmx $(<:.tex=.dvi)
	@rm -v $(<:.tex=.aux)
	@rm -v $(<:.tex=.dvi)
	@rm -v $(<:.tex=.log)
	@rm -v $(<:.tex=.out)
	@rm -v $(<:.tex=.toc)

install:
	@mkdir -vp $(DESTDIR)/slide $(DESTDIR)/article
	@for fn in `ls *.sli.pdf`; \
	do \
		cp -v $${fn} $(DESTDIR)/slide/$${fn%sli.pdf}pdf; \
	done
	@for fn in `ls *.pdf`; \
	do \
		cp -v $${fn} $(DESTDIR)/article/$${fn%pdf}pdf; \
	done
	@cp -v $(PLAN_PDF) $(DESTDIR)/

clean:
	@for set in $(wildcard *.tex); \
	do \
		rm -rvf $${set%.tex}; \
		for fn in `ls $${set%tex}*`; \
		do \
			if [ $${fn##*.} != tex ]; then rm -rvf $$fn; fi \
		done \
	done
