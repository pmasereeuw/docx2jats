<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xlink="http://www.w3.org/1999/xlink" 
    xmlns:pcm="http://www.masereeuw.nl/xslt/3.0/functions"
    expand-text="yes"
    exclude-result-prefixes="xs pcm" version="3.0">
    
    <xsl:template match="/">
        <graphics>
            <xsl:for-each select="distinct-values(//graphic/@xlink:href)">
                <graphic href="{.}"/>
            </xsl:for-each>
        </graphics>
    </xsl:template>
    
</xsl:stylesheet>
