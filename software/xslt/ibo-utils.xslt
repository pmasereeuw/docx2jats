<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pcm="http://www.masereeuw.nl/xslt/3.0/functions"
    exclude-result-prefixes="xs pcm" version="3.0">
    
    <xsl:function name="pcm:get-ibo-uuid" as="xs:string">
        <xsl:value-of select="'id-' || pcm:get-uuid()"/>
    </xsl:function>
    
</xsl:stylesheet>
