<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pcm="http://www.masereeuw.nl/xslt/3.0/functions"
    expand-text="yes"
    exclude-result-prefixes="xs pcm" version="3.0">
    
    <xsl:template match="styled-content[empty(@* except (@id, @style)) and normalize-space() eq '']">
        <!-- Spaties (of zelfs lege tekst) met een stijl hebben geen zin (behalve underline?), zeker als er geen bijzondere attributen zijn.
        -->
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="styled-content">
        <xsl:choose>
            <xsl:when test="@style eq 'IB-hyperlink'">
                <!-- Hyperlink-styles zonder hyperlink zijn blijven staan; verwijder ze. Deze test werkt expres niet als er meer stijlen zijn. -->
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:when test="empty(@* except (@id, @style)) and normalize-space() eq ''">
                <!-- Spaties (of zelfs lege tekst) met een stijl hebben geen zin (behalve underline?), zeker als er geen bijzondere attributen zijn. -->
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:otherwise>
                <!-- IBO does not want styled-content, but we leave it to be able to tell what might be wrong. -->
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>
