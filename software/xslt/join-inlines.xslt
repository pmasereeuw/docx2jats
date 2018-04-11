<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pcm="http://www.masereeuw.nl/xslt/3.0/functions"
    expand-text="yes"
    exclude-result-prefixes="xs pcm" version="3.0">
    
    <xsl:function name="pcm:get-inline-name"  as="xs:string">
        <xsl:param name="node" as="node()"/>
        <xsl:variable name="result" as="xs:string">
            <xsl:choose>
                <xsl:when test="$node/self::element()"><xsl:value-of select="local-name($node)"/></xsl:when>
                <xsl:when test="$node/self::text()[normalize-space() eq '']"><xsl:value-of select="if (exists($node/preceding-sibling::*)) then local-name($node/preceding-sibling::*[1]) else ''"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="''"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:value-of select="$result"/>
    </xsl:function>
    
    <xsl:template match="*[italic | bold | sup | sub]" mode="#all">
        <!-- See fix-inlines.xslt for inline styles. For instance, there is no underline. -->
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:for-each-group select="node()" group-adjacent="pcm:get-inline-name(.)">
                <xsl:choose>
                    <xsl:when test="current-grouping-key() ne ''">
                        <xsl:element name="{current-grouping-key()}">
                            <xsl:apply-templates select="current-group()" mode="suppress-inline"/>
                        </xsl:element>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="current-group()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each-group>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="italic|bold|sup|sup" mode="suppress-inline">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="node() | @*" mode="#all" priority="-1">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>
