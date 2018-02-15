<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:pcm="http://www.masereeuw.nl/xslt/3.0/functions" exclude-result-prefixes="xs pcm" version="3.0">
    
    <xsl:key name="styled-contents" match="styled-content" use="@id"/>
    
    <xsl:template match="xref[@rid]">
        <xsl:variable name="styled-content-element" select="key('styled-contents', @rid)" as="element(styled-content)?"/>
        <xsl:copy>
            <xsl:apply-templates select="@* except @rid"/>
            <xsl:attribute name="rid" select="if ($styled-content-element[not(node())]) then $styled-content-element/ancestor::*[@id][1]/@id else @rid"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="styled-content[not(node())]"/>
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
