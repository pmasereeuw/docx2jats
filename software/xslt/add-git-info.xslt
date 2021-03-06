<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" expand-text="yes" version="3.0">

    <xsl:param name="git-branch" required="yes"/>
    <xsl:param name="git-version" required="yes"/>
    
    <xsl:template match="/*">
       <xsl:copy>
           <xsl:comment>Generated on {current-dateTime()} by docx2jats4ib, software version (git) {$git-version}, branch: {$git-branch}.</xsl:comment>
           <xsl:apply-templates/>
       </xsl:copy> 
    </xsl:template>
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
