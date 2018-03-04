<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pcm="http://www.masereeuw.nl/xslt/3.0/functions"
    expand-text="yes"
    exclude-result-prefixes="xs pcm" version="3.0">
    
    <xsl:variable name="NOTE-FIRST-STYLE" as="xs:string" select="'IB-note_heading1'"/>
    <xsl:variable name="NOTE-INDICATOR-STYLE" as="xs:string" select="'IB-note'"/>
    <xsl:variable name="CAPTION-FIRST-STYLE" as="xs:string" select="'IB-caption_number'"/>
    <xsl:variable name="CAPTION-NEXT-STYLE" as="xs:string" select="'IB-caption_text'"/>
    <xsl:variable name="CONTINUED-LIST_STYLE" as="xs:string" select="'IB-continued-list'"/>
    
    <xsl:function name="pcm:style-pi-contains"  as="xs:boolean">
        <xsl:param name="context" as="element()"/>
        <xsl:param name="stylename" as="xs:string"/>
        <xsl:sequence select="exists($context/processing-instruction(style)[$stylename = tokenize(., '\s+')])"/>
    </xsl:function>
    
    <xsl:function name="pcm:preceding-belongs-to-stylegroup"  as="xs:boolean">
        <xsl:param name="preceding" as="element()"/>
        <xsl:param name="name-first-style" as="xs:string"/>
        <xsl:param name="name-indicator-style" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="not($preceding)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:when test="pcm:style-pi-contains($preceding, $name-first-style)">
                <xsl:sequence select="true()"/>
            </xsl:when>
            <xsl:when test="pcm:style-pi-contains($preceding, $name-indicator-style)">
                <xsl:sequence select="pcm:preceding-belongs-to-stylegroup($preceding/preceding-sibling::*[1], $name-first-style, $name-indicator-style)"/>
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
    
    <xsl:function name="pcm:is-followed-by-continuation-list"  as="xs:boolean">
        <xsl:param name="l" as="element()"/>
        <xsl:variable name="next" as="element()?" select="$l/following-sibling::*[1]"/>
        <xsl:choose>
            <xsl:when test="empty($next)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:when test="$next/self::list">
                <xsl:sequence select="pcm:style-pi-contains($next, $CONTINUED-LIST_STYLE)"/>
            </xsl:when>
            <xsl:when test="$next/self::p">
                <xsl:sequence select="pcm:is-followed-by-continuation-list($next)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- **** boxed-text *** -->
    
    <xsl:template match="p[pcm:style-pi-contains(., $NOTE-FIRST-STYLE)]">
        <boxed-text>
            <xsl:apply-templates select="." mode="boxed-text"/>
            <xsl:iterate select="following-sibling::*">
                <xsl:choose>
                    <xsl:when test="pcm:style-pi-contains(., $NOTE-INDICATOR-STYLE)">
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
    <xsl:template match="*[pcm:style-pi-contains(., $NOTE-INDICATOR-STYLE) and pcm:preceding-belongs-to-stylegroup(preceding-sibling::*[1], $NOTE-FIRST-STYLE, $NOTE-INDICATOR-STYLE)]"/>

    <xsl:template match="p[pcm:style-pi-contains(., $NOTE-FIRST-STYLE)]" mode="boxed-text">
        <caption content-type="box-title"><title><xsl:apply-templates select="@* | node()"/></title></caption>
    </xsl:template>
    
    <xsl:template match="*[pcm:style-pi-contains(., $NOTE-INDICATOR-STYLE) and not(pcm:style-pi-contains(., $NOTE-FIRST-STYLE))]" mode="boxed-text">
        <xsl:copy><xsl:apply-templates select="@* | node()"/></xsl:copy>
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
    
    <!-- **** continued list **** -->
    
    <!-- TODO Do there need to be restricions on the list-type, e.g. not continuation for ordered lists? And should be check if the adjacent lists have the same type? -->
    <xsl:template match="list[pcm:is-followed-by-continuation-list(.)]">
        <xsl:copy>
            <!-- TODO Generate an id conforming to IBO's wishes? -->
            <xsl:attribute name="id" select="'list-' || generate-id()"></xsl:attribute>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="list[pcm:style-pi-contains(., $CONTINUED-LIST_STYLE)]">
        <xsl:copy>
            <!-- TODO Generate an id conforming to IBO's wishes? -->
            <xsl:attribute name="continued-from" select="'list-' || generate-id(preceding-sibling::list[1])"></xsl:attribute>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- ** styles (for table) ** -->
    
    <xsl:template match="@style">
        <xsl:variable name="tokenized" as="xs:string*" select="tokenize(., '\s+')"/>
        <xsl:variable name="adjusted-styles" as="xs:string*">
            <xsl:for-each select="$tokenized">
                <xsl:variable name="simplified" as="xs:string" select="if (starts-with(., 'CSS_')) then substring-after(., 'CSS_') else ."/>
                <xsl:choose>
                    <xsl:when test="starts-with($simplified, 'background-color_')"><xsl:value-of select="'background:#ddd'"/></xsl:when>
                    <xsl:when test="starts-with($simplified, 'border-collapse')"><xsl:sequence select="()"/></xsl:when>
                    <xsl:otherwise><xsl:value-of select="$simplified"/></xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:variable name="text-align" as="xs:string?">
            <xsl:choose>
                <xsl:when test="parent::td">
                    <xsl:variable name="p" as="element(p)?" select="parent::td/p[1]"/>
                    <!-- Sample text-align pi value: IB-text-align_center -->
                    <xsl:variable name="text-align" as="xs:string?" select="tokenize($p/processing-instruction(style), ' ')[starts-with(., 'IB-text-align_')]"/>
                    
                    <xsl:sequence select="if (exists($text-align)) then 'text-align:' || substring-after($text-align, '_') else ()"/>
                </xsl:when>
                <xsl:otherwise><xsl:sequence select="()"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:attribute name="style" select="string-join(($adjusted-styles, $text-align), ';')"/>
    </xsl:template>
    
</xsl:stylesheet>
