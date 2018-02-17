<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pcm="http://www.masereeuw.nl/xslt/3.0/functions"
    exclude-result-prefixes="xs pcm" version="3.0">
    
    <xsl:include href="os-utils.xslt"/>
    <xsl:include href="ibo-utils.xslt"/>
    
    <xsl:template match="sec">
        <xsl:copy>
            <xsl:if test="not(@id)">
                <xsl:variable name="first-letter" as="xs:string" select="substring(name(.), 1, 1)"/>
                <xsl:variable name="num" as="xs:string"><xsl:number level="multiple" format="1.1"/></xsl:variable>
                <xsl:attribute name="id" select="$first-letter || $num"/>
            </xsl:if>
            <xsl:apply-templates select="node() | @*"/>            
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="table-wrap | ref | fig">
        <xsl:copy>
            <xsl:if test="not(@id)">
                <xsl:variable name="first-letter" as="xs:string" select="substring(name(.), 1, 1)"/>
                <xsl:variable name="num" as="xs:string"><xsl:number level="any" format="1"/></xsl:variable>
                <xsl:attribute name="id" select="$first-letter || $num"/>
            </xsl:if>
            <xsl:apply-templates select="node() | @*"/>            
        </xsl:copy>
    </xsl:template>

   <xsl:template match="node() | @*">
       <xsl:copy>
           <xsl:apply-templates select="node() | @*"/>
       </xsl:copy>
   </xsl:template>
    
</xsl:stylesheet>
