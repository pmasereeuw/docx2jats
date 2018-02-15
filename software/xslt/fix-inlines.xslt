<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pcm="http://www.masereeuw.nl/xslt/3.0/functions"
    expand-text="yes"
    exclude-result-prefixes="xs pcm" version="3.0">
    
    <xsl:template match="styled-content[@style = ('IB-italic', 'IB-italics', 'IB-font-style_italic', 'IB-italic IB-font-style_italic')]">
        <italic><xsl:apply-templates select="@* except @style | node()"/></italic>
    </xsl:template>
    
    <xsl:template match="styled-content[@style = ('IB-bold', 'IB-font-weight_bold', 'IB-bold IB-font-weight_bold')]">
        <bold><xsl:apply-templates select="@* except @style | node()"/></bold>
    </xsl:template>
    
    <xsl:template match="styled-content[@style = ('IB-font-weight_bold IB-font-style_italic', 'IB-font-style_italic IB-font-weight_bold')]">
        <italic><bold><xsl:apply-templates select="@* except @style | node()"/></bold></italic>
    </xsl:template>
    
    <xsl:template match="styled-content[@style = ('IB-vertical-align_super', 'IB-superscript')]">
        <sup><xsl:apply-templates select="@* except @style | node()"/></sup>
    </xsl:template>
    
    <xsl:template match="styled-content[@style = ('IB-vertical-align_sub', 'IB-subscript')]">
        <sub><xsl:apply-templates select="@* except @style | node()"/></sub>
    </xsl:template>
    
    <xsl:template match="styled-content[@style eq 'IB-subscript IB-font-style_italic']">
        <sub><italic><xsl:apply-templates select="@* except @style | node()"/></italic></sub>
    </xsl:template>

    <xsl:template match="styled-content[@style eq 'IB-superscript IB-font-style_italic']">
        <sub><italic><xsl:apply-templates select="@* except @style | node()"/></italic></sub>
    </xsl:template>
    
    <xsl:template match="*[self::ext-link or self::xref]/styled-content[@style eq 'IB-hyperlink']">
        <!-- Verwijder hyperlink style, but only below ext-link or xref. -->
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="styled-content[empty(@* except (@id, @style)) and @style eq 'IB-word_bookmark IB-id-']">
        <!-- Kenmerk niet (meer?) nodig, verwijder het. -->
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>
