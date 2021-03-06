<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    expand-text="yes"
    version="3.0">
    
    <xsl:param name="prefix-to-rng-schema" as="xs:string" required="yes"/>
    <xsl:param name="prefix-to-sch-schema" as="xs:string" required="yes"/>
    
    <!-- If the schema prefix was set to './', set it to empty (the calling scripts use ./ because dealing/testing with empty strings is difficult in Bash scripts). -->
    <xsl:variable name="modified-prefix-to-rng-schema" as="xs:string" select="if ($prefix-to-rng-schema eq './') then '' else $prefix-to-rng-schema"/>
    <xsl:variable name="modified-prefix-to-sch-schema" as="xs:string" select="if ($prefix-to-sch-schema eq './') then '' else $prefix-to-sch-schema"/>
    
    <xsl:template match="/">
        <xsl:copy>
            <xsl:processing-instruction name="xml-model">href="{$modified-prefix-to-rng-schema}JATS-journalpublishing1-mathml3.rng" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:processing-instruction>
            <xsl:processing-instruction name="xml-model">href="{$modified-prefix-to-sch-schema}ib-rules.sch" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:processing-instruction>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>
