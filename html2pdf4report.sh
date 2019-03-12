conf_path=/Bio/Pipeline/Module/ReportFactory3/ReportFactory/PDF_Config

wkhtmltopdf --footer-html $conf_path/footer.html -T 10mm -B 16mm -L 0mm -R 0mm cover $conf_path/front_cover.html toc --xsl-style-sheet $conf_path/css/toc.xsl --disable-dotted-lines $1 cover $conf_path/back_cover.html $
2
