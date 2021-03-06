SFUSER=rahtz
JING=jing
SAXON=java -jar Test/lib/Saxon-HE-9.4.0.6.jar
DOTDOTSAXON=java -jar ../Test/lib/Saxon-HE-9.4.0.6.jar
SAXON_ARGS=-ext:on

DIRS=bibtex common docx dtd docbook epub epub3 fo html html5 json latex latex nlm odd odds odt pdf profiles/default rdf relaxng rnc slides tbx tcp tite tools txt html xsd xlsx pdf

SCRIPTS=docbooktotei docxtotei odttotei transformtei tcptotei xlsxtotei \
	teitodocx 	teitodtd 	teitoepub \
	teitoepub3 	teitofo 	teitohtml \
	teitohtml5 	teitojson 	teitolatex \
	teitoodt 	teitordf 	teitorelaxng \
	teitornc 	teitoslides 	teitotxt \
	teitoxsd	teitopdf	teitobibtex teitodocbook teitoodd
PREFIX=/usr
OXY=/usr/share/oxygen
DOCTARGETS= \
	latex/latex.xsl \
	html/html.xsl \
	fo/fo.xsl \
	tcp/tcp2tei.xsl \
	odds/odd2odd.xsl \
	odds/odd2relax.xsl \
	odds/odd2dtd.xsl \
	slides/teihtml-slides.xsl \
	slides/teilatex-slides.xsl \
	profiles/default/csv/from.xsl		\
	profiles/default/csv/to.xsl	\
	profiles/default/docbook/from.xsl	\
	profiles/default/docx/from.xsl \
	profiles/default/docx/to.xsl \
	profiles/default/dtd/to.xsl	\
	profiles/default/epub/to.xsl	\
	profiles/default/fo/to.xsl	\
	profiles/default/html/to.xsl \
	profiles/default/latex/to.xsl \
	profiles/default/lite/to.xsl \
	profiles/default/odt/from.xsl \
	profiles/default/odt/to.xsl \
	profiles/default/p4/from.xsl \
	profiles/default/relaxng/to.xsl	

PROFILEDOCTARGETS=\
	profiles/enrich/docx/from.xsl \
	profiles/enrich/docx/to.xsl \
	profiles/enrich/fo/to.xsl \
	profiles/enrich/html/to.xsl \
	profiles/enrich/latex/to.xsl 

.PHONY: doc release common profiles $(PROFILEDOCTARGETS) $(DOCTARGETS)

default: check test release

check:
	@echo Checking you have running XML tools and Perl before trying to run transform...
	@echo -n Perl: 
	@which perl || exit 1
	@echo -n xmllint: 
	@which xmllint || exit 1
	@echo -n jing: 
	@which ${JING} || exit 1

v:
	perl -p -i -e "s+AppVersion.*/AppVersion+AppVersion>`cat VERSION`</AppVersion+" docx/to/application.xsl

build:
	@echo BUILD Copy main XSL files
	test -d release/xsl/xml/tei/stylesheet || mkdir -p release/xsl/xml/tei/stylesheet/
	for i in  ${DIRS} ; do \
		tar cf - $$i | (cd release/xsl/xml/tei/stylesheet; tar xf - ); \
	done


common: names
	@echo BUILD Copy common files and documentation
	test -d release/xslcommon/xml/tei/stylesheet || mkdir -p release/xslcommon/xml/tei/stylesheet
	cp names.xml catalog.xml VERSION *.css i18n.xml release/xslcommon/xml/tei/stylesheet

names:
	$(SAXON) -it:main tools/getnames.xsl > names.xml

profiles: 
	@echo BUILD Copy profiles
	test -d release/xslprofiles/xml/tei/stylesheet || mkdir -p release/xslprofiles/xml/tei/stylesheet
	tar cf - profiles | (cd release/xslprofiles/xml/tei/stylesheet; tar xf - )

doc: oxygendoc
	@echo BUILD Compile documentation
	test -d release/xslcommon/doc/tei-xsl || mkdir -p release/xslcommon/doc/tei-xsl
	$(SAXON) -o:doc/index.xml doc/teixsl.xml doc/param.xsl 
	$(SAXON) -o:doc/style.xml doc/teixsl.xml  doc/paramform.xsl 
	$(SAXON) -o:release/xslcommon/doc/tei-xsl/index.html doc/index.xml profiles/tei/html5/to.xsl cssFile=tei.css 
	$(SAXON) -o:release/xslcommon/doc/tei-xsl/style.html doc/style.xml  profiles/default/html/to.xsl 
	cp doc/*.png doc/teixsl.xml doc/style.xml release/xslcommon/doc/tei-xsl
	cp VERSION tei.css ChangeLog LICENCE release/xslcommon/doc/tei-xsl

oxygendoc:
	# when building Debain packages, the script runs under
	# fakeroot, and the oxygen script then tries to look in /root/.com.oxygenxml, and fails.  
	# The answer is to tweak the stylesheetDocumentation.sh script 
	@echo text for existence of file $(OXY)/stylesheetDocumentation.sh and make stylesheet documentation if it exists
	if test -f $(OXY)/stylesheetDocumentation.sh; then perl -pe "s+-Djava.awt+-Djava.awt -Duser.home=/tmp/+; s+OXYGEN_HOME=.*+OXYGEN_HOME=/usr/share/oxygen+" < $(OXY)/stylesheetDocumentation.sh > ./runDoc.sh; chmod 755 runDoc.sh;  cp -f $(OXY)/licensekey.txt .;  $(MAKE) ${DOCTARGETS} ${PROFILEDOCTARGETS}; rm -f licensekey.txt runDoc.sh; fi

teioo.jar:
	(cd odt;  mkdir TEIP5; $(DOTDOTSAXON) -o:TEIP5/teitoodt.xsl -s:teitoodt.xsl expandxsl.xsl ; cp odttotei.xsl TEIP5.ott teilite.dtd TEIP5; jar cf ../teioo.jar TEIP5 TypeDetection.xcu ; rm -rf TEIP5)

test: clean build common names debversion
	@echo BUILD Run tests
	(cd Test; make)

dist: clean release
	-rm -f tei-xsl-`cat VERSION`.zip
	(cd release/xslcommon; 		zip -r -q ../../tei-xsl-`cat ../../VERSION`.zip .)
	(cd release/xsl;     		zip -r -q ../../tei-xsl-`cat ../../VERSION`.zip .)
	(cd release/xslprofiles;    	zip -r -q ../../tei-xsl-`cat ../../VERSION`.zip .)
	-rm -rf dist
	mkdir dist
	(cd release/xsl; tar cf - .)         | (cd dist; tar xf -)
	(cd release/xslprofiles; tar cf - .) | (cd dist; tar xf -)
	(cd release/xslcommon/; tar cf - .)  | (cd dist; tar xf -)

release: common doc oxygendoc build profiles

installxsl: build teioo.jar
	mkdir -p ${PREFIX}/share/xml/tei/stylesheet
	cp -r lib teioo.jar ${PREFIX}/share/xml/tei/stylesheet
	(cd release/xsl; tar cf - .) | (cd ${PREFIX}/share; tar xf  -)
	mkdir -p ${PREFIX}/bin
	for i in $(SCRIPTS); do \
	  cp $$i ${PREFIX}/bin/$$i; \
	  chmod 755 ${PREFIX}/bin/$$i; \
	  perl -p -i -e 's+^APPHOME=.*+APPHOME=/usr/share/xml/tei/stylesheet+' ${PREFIX}/bin/$$i; \
	done

installprofiles: install-profiles-files install-profiles-docs

install-profiles-docs: 
	mkdir -p release/xslprofiles/doc
	@echo text for existence of file $(OXY)/stylesheetDocumentation.sh
	if test -f $(OXY)/stylesheetDocumentation.sh; then perl -pe "s+-Djava.awt+-Djava.awt -Duser.home=/tmp/+; s+OXYGEN_HOME=.*+OXYGEN_HOME=/usr/share/oxygen+" < $(OXY)/stylesheetDocumentation.sh > ./runDoc.sh; chmod 755 runDoc.sh;  cp -f $(OXY)/licensekey.txt .;  $(MAKE) ${PROFILEDOCTARGETS}; rm -f licensekey.txt runDoc.sh; fi
	(cd release/xslprofiles/doc; tar cf - .) | (cd ${PREFIX}/share/doc; tar xf -)

install-profiles-files:
	test -d release/xslprofiles/xml/tei/stylesheet || mkdir -p release/xslprofiles/xml/tei/stylesheet/
	mkdir -p ${PREFIX}/share/xml/
	mkdir -p ${PREFIX}/share/doc/
	tar cf - --exclude default profiles | (cd release/xslprofiles/xml/tei/stylesheet; tar xf - )
	(cd release/xslprofiles; tar cf - .) | (cd ${PREFIX}/share; tar xf  -)

${PROFILEDOCTARGETS}:
	echo process doc for $@
	ODIR=release/xslprofiles/doc/tei-xsl/`dirname $@` ./runDoc.sh $@ -cfg:doc/oxydoc.cfg
	(cd `dirname $@`; tar cf - release) | tar xf -
	rm -rf `dirname $@`/release

${DOCTARGETS}:
	echo process doc for $@
	ODIR=release/xsl/doc/tei-xsl/`dirname $@` ./runDoc.sh $@ -cfg:doc/oxydoc.cfg
	(cd `dirname $@`; tar cf - release) | tar xf -
	rm -rf `dirname $@`/release

installcommon: doc common
	mkdir -p ${PREFIX}/lib/cgi-bin
	cp doc/stylebear ${PREFIX}/lib/cgi-bin/stylebear
	chmod 755 ${PREFIX}/lib/cgi-bin/stylebear
	mkdir -p ${PREFIX}/share/doc/
	mkdir -p ${PREFIX}/share/xml/
	(cd release/xslcommon/doc; tar cf - .) | (cd ${PREFIX}/share/doc; tar xf -)
	(cd release/xslcommon/xml; tar cf - .) | (cd ${PREFIX}/share/xml; tar xf -)

install: doc installxsl installprofiles installcommon 

debversion:
	sh ./mydch debian-tei-xsl/debian/changelog

deb: debversion
	@echo BUILD Make Debian packages
	rm -f tei*xsl*_*deb
	rm -f tei*xsl*_*changes
	rm -f tei*xsl*_*build
	(cd debian-tei-xsl; debclean;debuild --no-lintian  -nc -b -uc -us)

sfupload:
	rsync -e ssh tei-xsl-`cat VERSION`.zip ${SFUSER},tei@frs.sourceforge.net:/home/frs/project/t/te/tei/Stylesheets

log:
	(LastDate=`head -1 ChangeLog | awk '{print $$1}'`; \
	echo changes since $$LastDate; \
	./git-to-changelog --since=$$LastDate > newchanges)
	mv ChangeLog oldchanges
	cat newchanges oldchanges > ChangeLog
	rm newchanges oldchanges

clean:
	echo "" > test~
	rm -f profile1.html profile2.html profile.xml
	find . -name "*~"  | xargs rm
	rm -f tei-xsl-*.zip	
	rm -rf tei-xsl_*
	rm -f doc/stylebear doc/style.xml doc/customize.xml doc/teixsl.html doc/index.xml
	rm -rf release dist
	(cd Test; make clean)
	rm -rf tei-p5-xsl_*
	rm -rf tei-p5-xsl2_*
	-(cd debian-tei-xsl/debian;  rm -rf tei-xsl)
	rm -f teioo.jar
	rm -rf docx/ImageInfo/bin
	rm -f names.xml licensekey.txt runDoc.sh

tags:
	etags `find . -name "*.xsl" | grep -v "slides/" | grep -v "latex/" | grep -v "html/" | grep -v "fo/" | grep -v "common2/" | grep -v "doc/" `

