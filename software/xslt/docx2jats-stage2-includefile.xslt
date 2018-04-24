<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"
    xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:pcm="http://www.masereeuw.nl/xslt/3.0/functions" xmlns:rels="http://schemas.openxmlformats.org/package/2006/relationships"
    xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:xlink="http://www.w3.org/1999/xlink" exclude-result-prefixes="xs w pic wp a pcm rels r o" expand-text="yes" version="3.0">
    
    <!-- Stylenames (from the Word styles document, but normalized (e.g., spaces to underscore, lower case) that
         indicate that we are dealing with a list:
    -->
    <xsl:variable name="bullet_list-style-names" as="xs:string+" select="('list_unordered', 'continued_list_unordered', 'listbullet', 'list_bullet', 'list_(bullet)', 'note_list_(bullet)')"/>
    <xsl:variable name="number_list-style-names" as="xs:string+" select="('list_arabic', 'continued_list_arabic', 'list_number')"/>
    
    <xsl:variable name="list-style-names" as="xs:string+" select="($bullet_list-style-names, $number_list-style-names)"/>
    
    <xsl:function name="pcm:get-list-type" as="xs:string">
        <xsl:param name="style" as="xs:string?"/>
        <xsl:param name="level" as="xs:integer?"/>
        <xsl:choose>
            <xsl:when test="$style = $bullet_list-style-names">
                <xsl:value-of select="'bullet'"/>
            </xsl:when>
            <xsl:when test="$style = $number_list-style-names">
                <xsl:value-of select="'order'"/>
            </xsl:when>
            <!-- TODO Nog niet gezien in sample content: -->
            <xsl:when test="$style eq 'lowerLetter'">
                <xsl:value-of select="'lower-alpha'"/>
            </xsl:when>
            <xsl:when test="$style eq 'upperLetter'">
                <xsl:value-of select="'upper-alpha'"/>
            </xsl:when>
            <xsl:when test="$style eq 'lowerRoman'">
                <xsl:value-of select="'lower-roman'"/>
            </xsl:when>
            <xsl:when test="$style eq 'upperRoman'">
                <xsl:value-of select="'upper-roman'"/>
            </xsl:when>
            <xsl:when test="not($style)">
                <xsl:value-of select="'none'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$style"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="pcm:nextListItem" as="element(LI)?">
        <xsl:param name="currentLi" as="element(LI)"/>
        <xsl:sequence select="$currentLi/following-sibling::*[1][self::LI]"/>
    </xsl:function>
    
    <xsl:function name="pcm:previousListItem" as="element(LI)?">
        <xsl:param name="currentLi" as="element(LI)"/>
        <xsl:sequence select="$currentLi/preceding-sibling::*[1][self::LI]"/>
    </xsl:function>
    
    <xsl:function name="pcm:isFirstListItem" as="xs:boolean">
        <xsl:param name="currentLi" as="element(LI)"/>
        <!-- Assuming that two lists will never be adjacent; there will always be an intermediate paragraph or the start of a chapter. -->
        <xsl:sequence select="not(pcm:previousListItem($currentLi))"/>
    </xsl:function>
    
    <xsl:function name="pcm:findFirstItemBeyondNestedList" as="element(LI)?">
        <!-- At the toplevel call of this nested function, the listItem parameter should reference the first item of the nested list.
             The function returns the list item that comes after the nested list (if it can be found; otherwise, the empty sequence is returned.
             The item beyond the nested list is identified by having the same level as given by the parameter.
        -->
        <xsl:param name="listItem" as="element(LI)?"/>
        <xsl:param name="requiredLevel" as="xs:integer"/>
        
        <xsl:choose>
            <xsl:when test="$listItem">
                <xsl:choose>
                    <xsl:when test="xs:integer($listItem/@level) gt $requiredLevel">
                        <!-- Still at a nested list, or at an even deeper nested one. -->
                        <xsl:sequence select="pcm:findFirstItemBeyondNestedList(pcm:nextListItem($listItem), $requiredLevel)"/>
                    </xsl:when>
                    <xsl:when test="xs:integer($listItem/@level) eq $requiredLevel">
                        <!-- Found. -->
                        <xsl:sequence select="$listItem"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <!-- No list item or start of a new list (with another numid) -->
                <xsl:sequence select="()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template match="@* | node()" mode="stage2">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="stage2"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="LI[pcm:isFirstListItem(.)]" mode="stage2">
        <xsl:call-template name="doList">
            <xsl:with-param name="listItem" select="."/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="LI[not(pcm:isFirstListItem(.))]" mode="stage2"/>
    <!-- Non-first list item is pulled, not pushed -->
    
    <xsl:template name="doList">
        <xsl:param name="listItem" as="element(LI)" required="yes"/>
        
        <list list-type="{pcm:get-list-type($listItem/@style, $listItem/@level)}">
            <xsl:call-template name="doListItems">
                <xsl:with-param name="listItem" select="$listItem"/>
            </xsl:call-template>
            <xsl:processing-instruction name="style" select="$listItem/@style || ' ' || pcm:inferred-styles($listItem/@style)"/>
        </list>
    </xsl:template>
    
    <xsl:template name="doListItems">
        <xsl:param name="listItem" as="element(LI)" required="yes"/>
        
        <xsl:variable name="nextListItem" select="pcm:nextListItem($listItem)" as="element(LI)?"/>
        <xsl:variable name="nestedListFollows" select="$nextListItem and ($nextListItem/@level gt $listItem/@level)" as="xs:boolean"/>
        
        <xsl:for-each select="$listItem">
            <!-- One  iteration only -->
            <list-item>
                <xsl:apply-templates select="@* except @style | node()" mode="stage2"/>
                
                <xsl:if test="$nestedListFollows">
                    <xsl:call-template name="doList">
                        <xsl:with-param name="listItem" select="$nextListItem"/>
                    </xsl:call-template>
                </xsl:if>
            </list-item>
            
            <!-- Deal with the rest of the list, if any -->
            <xsl:choose>
                <xsl:when test="$nestedListFollows">
                    <!-- Continue beyond the nested list: -->
                    <xsl:variable name="firstItemBeyondNestedList" select="pcm:findFirstItemBeyondNestedList($nextListItem, @level)" as="element(LI)?"/>
                    <xsl:if test="$firstItemBeyondNestedList">
                        <xsl:call-template name="doListItems">
                            <xsl:with-param name="listItem" select="$firstItemBeyondNestedList"/>
                        </xsl:call-template>
                    </xsl:if>
                </xsl:when>
                
                <xsl:when test="$nextListItem/@numid != $listItem/@numid"/>
                <!-- Here starts a new list, rely on the match-template for this situation. -->
                
                <xsl:when test="$nextListItem/@level = $listItem/@level">
                    <!-- Same level, so same list. -->
                    <xsl:call-template name="doListItems">
                        <xsl:with-param name="listItem" select="$nextListItem"/>
                    </xsl:call-template>
                </xsl:when>
                
                <xsl:otherwise>
                    <!-- Same numid, lower level, so end of the nested list (note that the higher level is already dealt with, because $nestedListFollows is true in that case). -->
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        
    </xsl:template>
    
    <xsl:template match="LI/@level | LI/@listtype" mode="stage2"/>
</xsl:stylesheet>