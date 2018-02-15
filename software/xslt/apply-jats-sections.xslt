<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pcm="http://www.masereeuw.nl/xslt/3.0/functions"
    expand-text="yes"
    exclude-result-prefixes="xs pcm" version="3.0">
    
    <xsl:param name="style-prefix" select="'PCM-'"/>
    
    <xsl:variable name="title-style" select="$style-prefix || 'title'"/>
    <!-- Be aware that heading-prefix will be part of a regex and may need to be escaped. -->
    <xsl:variable name="heading-prefix" select="$style-prefix || 'heading_'"/>
    
    <xsl:function name="pcm:style-contains"  as="xs:boolean">
        <xsl:param name="string" as="xs:string"/>
        <xsl:param name="required-value" as="xs:string"/>
        
        <xsl:sequence select="$required-value = tokenize($string, '\s+')"></xsl:sequence>
    </xsl:function>
    
    <xsl:function name="pcm:derive-heading-level" as="xs:integer?">
        <xsl:param name="e" as="element()"/>
        
        <xsl:variable name="stylepi" as="processing-instruction(style)?" select="$e/processing-instruction(style)"/>
        <xsl:variable name="tokenized-style" as="xs:string*" select="tokenize($stylepi, '\s+')"/>
        <xsl:variable name="regex" as="xs:string" select="'^' || $heading-prefix || '(\d)$'"/>
        <xsl:choose>
            <xsl:when test="not($stylepi)">
                <xsl:sequence select="()"/>
            </xsl:when>
            <xsl:when test="$title-style = $tokenized-style">
                <xsl:sequence select="0"/>
            </xsl:when>
            <xsl:when test="some $s in $tokenized-style satisfies matches($s, $regex)">
                <xsl:variable name="matching" as="xs:string" select="$tokenized-style[matches(., $regex)]"/>
                <xsl:sequence select="xs:integer(replace($matching, $regex, '$1'))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="pcm:p-has-required-level" as="xs:boolean">
        <xsl:param name="e" as="element()"/>
        <xsl:param name="required-level" as="xs:integer"/>
        <xsl:sequence select="exists($e/self::p) and pcm:derive-heading-level($e) eq $required-level"/>
    </xsl:function>
    
    <xsl:function name="pcm:style-matches"  as="xs:boolean">
        <xsl:param name="string" as="xs:string"/>
        <xsl:param name="regex" as="xs:string"/>
        
        <xsl:sequence select="some $s in tokenize($string, '\s+') satisfies matches($s, $regex)"></xsl:sequence>
    </xsl:function>
    
    <xsl:function name="pcm:is-p-containing-style"  as="xs:boolean">
        <xsl:param name="e" as="element(p)"/>
        <xsl:param name="stylename" as="xs:string"/>
        
        <xsl:sequence select="exists($e[pcm:style-contains(processing-instruction(style), $stylename)])"/>
    </xsl:function>
    
    <xsl:template name="apply-section">
        <xsl:param name="required-level" as="xs:integer" required="yes"/>
        <xsl:param name="group" as="node()*" required="yes"/>
        
        <xsl:choose>
            <xsl:when test="$required-level gt 9">
                <!-- No deeper group than level 9. -->
                <xsl:apply-templates select="$group"></xsl:apply-templates>
            </xsl:when>
            <xsl:when test="exists($group/self::p[pcm:p-has-required-level(., $required-level)])">
                <xsl:for-each-group select="$group" group-starting-with="p[pcm:p-has-required-level(., $required-level)]">
                    <xsl:choose>
                        <xsl:when test="current-group()[self::p[pcm:p-has-required-level(., $required-level)]]">
                            <sec>
                                <xsl:apply-templates select="current-group()[self::p[pcm:p-has-required-level(., $required-level)]]"/>
                                <xsl:call-template name="apply-section">
                                    <xsl:with-param name="required-level" select="$required-level + 1" as="xs:integer"/>
                                    <xsl:with-param name="group" select="current-group()[not(pcm:p-has-required-level(., $required-level))]"/>
                                </xsl:call-template>
                            </sec>    
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="current-group()"/>
                        </xsl:otherwise>
                    </xsl:choose>
               </xsl:for-each-group>
            </xsl:when>
            <xsl:otherwise>
                <!-- No heading for this level. Maybe a level was omitted, so try a deeper level. Of course, this may also be the normal situation at the deepest level of the document. -->
                <xsl:call-template name="apply-section">
                    <xsl:with-param name="required-level" select="$required-level + 1"/>
                    <xsl:with-param name="group" select="$group"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="body">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:call-template name="apply-section">
                <xsl:with-param name="required-level" select="0" as="xs:integer"/>
                <xsl:with-param name="group" select="node()"/>
            </xsl:call-template>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="p[exists(pcm:derive-heading-level(.))]">
        <title><xsl:apply-templates/></title>
    </xsl:template>
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
    