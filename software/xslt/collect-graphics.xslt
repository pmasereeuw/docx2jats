<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xlink="http://www.w3.org/1999/xlink" 
    xmlns:pcm="http://www.masereeuw.nl/xslt/3.0/functions"
    expand-text="yes"
    exclude-result-prefixes="xs pcm" version="3.0">
    
    <!-- Prefix used for references to resources (figures); if a folder is intended, it should end in a slash.
         It is only used for the value of the href in the conversion result. Therefore, it is removed from
         the XML elements that help copying the files.
    -->
    <xsl:param name="resource-prefix" select="''"/>

    <xsl:template match="/">
        <graphics>
            <xsl:for-each select="distinct-values(//graphic/@xlink:href[not(matches(., '^https?:'))])">
                <graphic href="{substring-after(., $resource-prefix)}"/>
            </xsl:for-each>
        </graphics>
    </xsl:template>
    
</xsl:stylesheet>
