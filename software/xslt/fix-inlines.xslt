<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pcm="http://www.masereeuw.nl/xslt/3.0/functions"
    expand-text="yes"
    exclude-result-prefixes="xs pcm" version="3.0">
    
    <xsl:key name="rids" match="@rid" use="."/>
    
    <xsl:function name="pcm:element-for-style"  as="element()?">
        <xsl:param name="styled-content-element" as="element(styled-content)"/>
        <xsl:param name="stylename" as="xs:string"/>

        <xsl:choose>
            <xsl:when test="$stylename eq 'IB-italic'"><italic/></xsl:when>
            <xsl:when test="$stylename eq 'IB-italics'"><italic/></xsl:when>
            <xsl:when test="$stylename eq 'IB-font-style_italic'"><italic/></xsl:when>
            <xsl:when test="$stylename eq 'IB-bold'"><bold/></xsl:when>
            <xsl:when test="$stylename eq 'IB-font-weight_bold'"><bold/></xsl:when>
            <xsl:when test="$stylename eq 'IB-superscript'"><sup/></xsl:when>
            <xsl:when test="$stylename eq 'IB-vertical-align_super'"><sup/></xsl:when>
            <xsl:when test="$stylename eq 'IB-subscript'"><sub/></xsl:when>
            <xsl:when test="$stylename eq 'IB-vertical-align_sub'"><sub/></xsl:when>
            <xsl:when test="$stylename eq 'IB-hyperlink'">
                <!-- Verwijder hyperlink style, but only below ext-link or xref. -->
                <xsl:choose>
                    <xsl:when test="$styled-content-element/parent::*[self::ext-link or self::xref]">
                        <xsl:sequence select="()"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <styled-content style="{$stylename}"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$stylename eq 'IB-word_bookmark'"><xsl:sequence select="()"/></xsl:when>
            <xsl:when test="$stylename eq 'IB-id-'"><xsl:sequence select="()"/></xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="pcm:name-in-list"  as="xs:boolean">
        <xsl:param name="element" as="element()"/>
        <xsl:param name="element-list" as="element()*"/>
        <xsl:sequence select="name($element) = (for $e in $element-list return name($e))"></xsl:sequence>
    </xsl:function>
    
    <xsl:template match="styled-content">
        <xsl:choose>
            <xsl:when test="empty(@* except @style)">
                <!-- The element with elements corresponding to the style names (content pulled inside tempate with name generate-elements); leave it out. -->
            </xsl:when>
            <xsl:when test="@id and empty(@* except (@id, @style))">
                <!-- Only other attribute is an id. Keep the element only if the id is referenced (in that case we'll have to see what to do: -->
                <xsl:choose>
                    <xsl:when test="exists(key('rids', @id))">
                        <xsl:copy>
                            <xsl:apply-templates select="node() | @*"/>
                        </xsl:copy>
                    </xsl:when>
                    <!-- Otherwise, do not copy, see above how the content will be maintained. -->
                    <xsl:otherwise/>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <!-- Keep the element so that we can see what's unexpected: -->
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates select="@style"></xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="styled-content/@style">
        <xsl:variable name="parent" as="element(styled-content)" select="parent::styled-content"/>
        <xsl:variable name="stylestrings" as="xs:string*" select="tokenize(., '\s+')"/>
        <xsl:iterate select="$stylestrings">
            <xsl:param name="new-stylestrings" as="xs:string*" select="$stylestrings"/>
            <xsl:param name="elements-to-be-generated" as="element()*" select="()"></xsl:param>
            
            <xsl:on-completion>
                <!-- Done with all stylenames, now generated the element names and then proceed with the content: -->
                <xsl:call-template name="generate-elements">
                    <xsl:with-param name="elements-to-be-generated" select="$elements-to-be-generated"/>
                    <xsl:with-param name="styled-content-element" select="$parent"/>
                </xsl:call-template>
            </xsl:on-completion>
            
            <xsl:variable name="element-for-style" as="element()?" select="pcm:element-for-style($parent, $new-stylestrings[1])"/>
            
            <!-- If there is an element for this style, and if it has not yet been used, add it to the set: -->
            <xsl:variable name="new-elements-to-be-generated" as="element()*"
                select="if (exists($element-for-style) and not(pcm:name-in-list($element-for-style, $elements-to-be-generated)))
                        then ($elements-to-be-generated, $element-for-style)
                        else $elements-to-be-generated"/>
            
            <xsl:next-iteration>
                <xsl:with-param name="new-stylestrings" select="subsequence($new-stylestrings, 2)"/>
                <xsl:with-param name="elements-to-be-generated" select="$new-elements-to-be-generated"/>
            </xsl:next-iteration>
        </xsl:iterate>
    </xsl:template>
    
    <xsl:template name="generate-elements">
        <xsl:param name="elements-to-be-generated" as="element()*" required="yes"/>
        <xsl:param name="styled-content-element" as="element(styled-content)" required="yes"/>
        
        <xsl:choose>
            <xsl:when test="exists($elements-to-be-generated)">
                <xsl:for-each select="$elements-to-be-generated[1]">
                    <!-- The for-each merely sets the context to the element to be copied. -->
                    <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:call-template name="generate-elements">
                            <xsl:with-param name="elements-to-be-generated" select="subsequence($elements-to-be-generated, 2)"/>
                            <xsl:with-param name="styled-content-element" select="$styled-content-element"/>
                        </xsl:call-template>
                    </xsl:copy>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$styled-content-element/node()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>
