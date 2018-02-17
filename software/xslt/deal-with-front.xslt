<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:pcm="http://www.masereeuw.nl/xslt/3.0/functions" exclude-result-prefixes="xs pcm" version="3.0">
    
    <xsl:include href="os-utils.xslt"/>
    <xsl:include href="ibo-utils.xslt"/>

    <xsl:template match="front/article-meta/title-group/article-title">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="(/article/body//title)[1]/node()" mode="pull-body-title-to-front"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="node() | @* except @id" mode="pull-body-title-to-front">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="pull-body-title-to-front"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="@id" mode="pull-body-title-to-front">
        <!-- Any id attribute that is copied to the front section should be replaced in order to remain unique. -->
        <xsl:attribute name="id" select="'front-' || ."/>
    </xsl:template>
    
</xsl:stylesheet>
