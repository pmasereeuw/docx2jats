<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pcm="http://www.masereeuw.nl/xslt/3.0/functions"
    expand-text="yes"
    exclude-result-prefixes="xs pcm" version="3.0">
    
    <xsl:variable name="NOTE-FIRST-STYLE" as="xs:string" select="'IB-note_heading1'"/>
    <xsl:variable name="NOTE-NEXT-STYLE" as="xs:string" select="'IB-note_body'"/>
    <xsl:variable name="CAPTION-FIRST-STYLE" as="xs:string" select="'IB-caption_number'"/>
    <xsl:variable name="CAPTION-NEXT-STYLE" as="xs:string" select="'IB-caption_text'"/>
    
    <xsl:function name="pcm:style-pi-contains"  as="xs:boolean">
        <xsl:param name="context" as="element()"/>
        <xsl:param name="stylename" as="xs:string"/>
        <xsl:sequence select="exists($context/processing-instruction(style)[$stylename = tokenize(., '\s+')])"/>
    </xsl:function>
    
    <xsl:function name="pcm:preceding-belongs-to-stylegroup"  as="xs:boolean">
        <xsl:param name="preceding" as="element()"/>
        <xsl:param name="name-first-style" as="xs:string"/>
        <xsl:param name="name-next-style" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="not($preceding)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:when test="pcm:style-pi-contains($preceding, $name-first-style)">
                <xsl:sequence select="true()"/>
            </xsl:when>
            <xsl:when test="pcm:style-pi-contains($preceding, $name-next-style)">
                <xsl:sequence select="pcm:preceding-belongs-to-stylegroup($preceding/preceding-sibling::*[1], $name-first-style, $name-next-style)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="pcm:fig-precedes-caption"  as="xs:boolean">
        <xsl:param name="preceding" as="element()"/>
        <xsl:choose>
            <xsl:when test="not($preceding)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:when test="$preceding/self::p[fig]">
                <xsl:sequence select="true()"/>
            </xsl:when>
            <xsl:when test="pcm:style-pi-contains($preceding, $CAPTION-FIRST-STYLE)">
                <xsl:sequence select="true()"/>
            </xsl:when>
            <xsl:when test="pcm:style-pi-contains($preceding, $CAPTION-NEXT-STYLE)">
                <xsl:sequence select="pcm:fig-precedes-caption($preceding/preceding-sibling::*[1])"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- **** boxed-text *** -->
    
    <xsl:template match="p[pcm:style-pi-contains(., $NOTE-FIRST-STYLE)]">
        <boxed-text>
            <xsl:apply-templates select="." mode="boxed-text"/>
            <xsl:iterate select="following-sibling::*">
                <xsl:choose>
                    <xsl:when test="pcm:style-pi-contains(., $NOTE-NEXT-STYLE)">
                        <xsl:apply-templates select="." mode="boxed-text"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:break/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:iterate>
        </boxed-text>
    </xsl:template>
    
    <!-- Element is pulled inside boxed-text. -->
    <xsl:template match="p[pcm:style-pi-contains(., $NOTE-NEXT-STYLE) and pcm:preceding-belongs-to-stylegroup(preceding-sibling::*[1], $NOTE-FIRST-STYLE, $NOTE-NEXT-STYLE)]"/>

    <xsl:template match="p[pcm:style-pi-contains(., $NOTE-FIRST-STYLE)]" mode="boxed-text">
        <caption><title><xsl:apply-templates select="@* | node()"/></title></caption>
    </xsl:template>
    
    <xsl:template match="p[pcm:style-pi-contains(., $NOTE-NEXT-STYLE)]" mode="boxed-text">
        <p><xsl:apply-templates select="@* | node()"/></p>
    </xsl:template>
    
    <!-- **** fig with caption *** -->
    
    <xsl:template match="fig[parent::p[following-sibling::*[1][self::p[pcm:style-pi-contains(., $CAPTION-FIRST-STYLE)]]]]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="parent::p/following-sibling::*[1][self::p]" mode="caption"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- Element is pulled inside fig. -->
    <xsl:template match="p[(pcm:style-pi-contains(., $CAPTION-FIRST-STYLE) or pcm:style-pi-contains(., $CAPTION-NEXT-STYLE)) and pcm:fig-precedes-caption(preceding-sibling::*[1])]"/>

    <xsl:template match="p[pcm:style-pi-contains(., $CAPTION-FIRST-STYLE)]" mode="caption">
        <caption>
            <title><xsl:apply-templates select="@* | node()"/></title>
            <xsl:apply-templates select="following-sibling::*[1][pcm:style-pi-contains(., $CAPTION-NEXT-STYLE)]" mode="caption"/>
        </caption>
    </xsl:template>
    
    <xsl:template match="p[pcm:style-pi-contains(., $CAPTION-NEXT-STYLE)]" mode="caption">
        <p><xsl:apply-templates select="@* | node()"/></p>
        <xsl:apply-templates select="following-sibling::*[1][self::p[pcm:style-pi-contains(., $CAPTION-NEXT-STYLE)]]" mode="caption"/>
    </xsl:template>
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>
