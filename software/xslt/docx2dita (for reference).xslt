<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"
    xmlns:pcm="http://www.masereeuw.nl/xslt/3.0/functions"
    xmlns:rels="http://schemas.openxmlformats.org/package/2006/relationships"
    exclude-result-prefixes="xs w pic pcm rels"
    version="2.0">
    
    <xsl:param name="noten-titel" select="'Noten'" as="xs:string"/>
    
    <!-- apply-table-borders: if 'yes', do a conversion of DOCX table borders to CSS border styles -->
    <xsl:param name="apply-table-borders" select="'no'"/>
    
    <!-- apply-table-backgrounds: if 'yes', do a conversion of DOCX table shading to CSS background-color styles -->
    <xsl:param name="apply-table-backgrounds" select="'no'"/>
    
    <xsl:param name="stylename-fullpageimage" select="'booktitle'" as="xs:string"></xsl:param>
    
    <!--<xsl:param name="allow-ol-start-attribute" select="'yes'"/>-->
    <!-- Not applicable for DITA. 
         Set to 'yes' if the start attribute is allowed on numbered lists (with irregular numbering. The start attribute is not allowed in XHTML and,
         therefore, not in epub. Set to 'no' (or anything not equal to 'yes') in order to generate an ol-start processing instruction with the
         start value.
    -->
    
    <!-- Prefix for generated outputclass names; note: do not use characters that need to be escaped in a regex -->
    <xsl:param name="outputclass-prefix" select="'PCM-'"/>

    <xsl:output method="xml" indent="no" doctype-public="-//OASIS//DTD DITA Topic//EN" doctype-system="topic.dtd"/>
    
    <!-- Wrapper for the doc() function sothat it may be redefined in an importing stylesheet. -->
    <xsl:function name="pcm:doc" as="node()?">
        <xsl:param name="docnode" as="document-node()"/>
        <xsl:param name="uri" as="xs:string?"/>
        <xsl:sequence select="doc($uri)"/>
    </xsl:function>
    
    <!-- Wrapper for the resolve-uri() function sothat it may be redefined in an importing stylesheet. -->
    <xsl:function name="pcm:resolve-uri" as="xs:anyURI?">
        <xsl:param name="relative" as="xs:string?"/>
        <xsl:param name="base" as="xs:string"/>
        <xsl:sequence select="resolve-uri($relative, $base)"/>
    </xsl:function>
    
    <!-- Wrapper for the base-uri() function sothat it may be redefined in an importing stylesheet. -->
    <xsl:function name="pcm:base-uri" as="xs:anyURI?">
        <xsl:param name="arg" as="node()?"/>
        <xsl:sequence select="base-uri($arg)"/>
    </xsl:function>
    
    <xsl:function name="pcm:get-word-document" as="node()">
        <xsl:param name="docnode" as="document-node()"/>
        <xsl:sequence select="pcm:doc($docnode, pcm:resolve-uri($worddocfile, pcm:base-uri($docnode)))"/>
    </xsl:function>
    
    <!-- Note: The input document is the _rels/rels file that points to the word/document.xml file (or whatever its name will be) -->
    <xsl:variable name="worddocfile"
        select="concat('../',
            /rels:Relationships/rels:Relationship[@Type='http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument']/@Target)"
        as="xs:string"
    />
    <xsl:variable name="worddoc" select="pcm:get-word-document(/)"/>
    
    <xsl:variable name="documentrelsfile" select="pcm:resolve-uri('_rels/document.xml.rels', pcm:base-uri($worddoc))"/>
    <xsl:variable name="documentrelsdoc" select="pcm:doc(/, $documentrelsfile)"/>
    
    <xsl:variable name="stylefile" select="$documentrelsdoc/rels:Relationships/rels:Relationship[@Type='http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles']/@Target"/>
    <xsl:variable name="styledoc" select="pcm:doc(/, pcm:resolve-uri($stylefile, pcm:base-uri($worddoc)))"/>

    <xsl:variable name="numberingfile" select="$documentrelsdoc/rels:Relationships/rels:Relationship[@Type='http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering']/@Target"/>
    <xsl:variable name="numberingdoc" select="pcm:doc(/, pcm:resolve-uri($numberingfile, pcm:base-uri($worddoc)))"/>

    <!-- If there are no footnotes, the documentrelsdoc does not contain a reference to a footnotes document. However, all seems
         to go well if this happens.
    -->
    <xsl:variable name="footnotefile" select="$documentrelsdoc/rels:Relationships/rels:Relationship[@Type='http://schemas.openxmlformats.org/officeDocument/2006/relationships/footnotes']/@Target"/>
    <xsl:variable name="footnotedoc" select="pcm:doc(/, pcm:resolve-uri($footnotefile, pcm:base-uri($worddoc)))"/>
    
    <xsl:variable name="FOOTNOTEPREFIX" select="'vn.'"/>
    <xsl:variable name="FOOTNOTEBACKPREFIX" select="concat('back.', $FOOTNOTEPREFIX)"/>
    
    <xsl:variable name="NL" select="'&#10;'"/>
    
    <xsl:function name="pcm:errormessage" as="xs:string">
        <xsl:param name="message" as="xs:string"/>
        <xsl:variable name="errormessage" select="concat('*error: ', $message, '*')"/>
        <xsl:message><xsl:value-of select="$errormessage"/></xsl:message>
        <xsl:value-of select="$errormessage"/>
    </xsl:function>
    
    <xsl:function name="pcm:replaceFunnyCharacters" as="xs:string">
        <xsl:param name="string"/>
        <xsl:value-of select="replace($string, ' ', '_')"/>
    </xsl:function>
    
    <xsl:function name="pcm:lookupParagraphStyleName" as="xs:string">
        <xsl:param name="styleid"/>
        <xsl:value-of select="pcm:replaceFunnyCharacters($styledoc/w:styles/w:style[@w:type='paragraph' and @w:styleId=$styleid]/w:name/@w:val)"/>
    </xsl:function>
    
    <xsl:function name="pcm:lookupListStyleName" as="xs:string">
        <xsl:param name="numid"/>
        <xsl:param name="ilvl"/>
        <xsl:variable name="abstractNumId" select="$numberingdoc/w:numbering/w:num[@w:numId=$numid]/w:abstractNumId/@w:val"/>
        <xsl:variable name="numFmt" select="$numberingdoc/w:numbering/w:abstractNum[@w:abstractNumId=$abstractNumId]/w:lvl[@w:ilvl=$ilvl]/w:numFmt/@w:val"/>
        
        <!--<xsl:message><xsl:value-of select="concat('lookupListStyleName, numid=', $numid, ', ilvl=', $ilvl, ', abstractNumId=', $abstractNumId, ', numFmt=', $numFmt)"/></xsl:message>-->
        <xsl:value-of select="pcm:replaceFunnyCharacters($numFmt)"/>
    </xsl:function>
    
    <xsl:function name="pcm:lookupCharactereStyleName" as="xs:string">
        <xsl:param name="styleid"/>
        <xsl:value-of select="pcm:replaceFunnyCharacters($styledoc/w:styles/w:style[@w:type='character' and @w:styleId=$styleid]/w:name/@w:val)"/>
    </xsl:function>
    
    <xsl:function name="pcm:determine-image-file-name" as="xs:string">
        <xsl:param name="cNvPrElement" as="element()?"/>
        <xsl:variable name="pathname">
            <xsl:choose>
                <xsl:when test="not($cNvPrElement)">*error: missing cNvPr element for image*</xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="$cNvPrElement/@descr"><xsl:value-of select="$cNvPrElement/@descr"/></xsl:when>
                        <xsl:when test="$cNvPrElement/@name"><xsl:value-of select="$cNvPrElement/@name"/></xsl:when>
                        <xsl:otherwise>*error: missing name and descr attribute for image at element <xsl:value-of select="name($cNvPrElement)"/>*</xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- Obtain the pathname part after the last slash or backslash: -->
        <xsl:analyze-string select="concat('/', $pathname)" regex="^.*[\\/](.*)$">
            <xsl:matching-substring>
                <xsl:value-of select="regex-group(1)"/>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="pcm:build-field-private" as="xs:string">
        <xsl:param name="field" as="element()?"/>
        <xsl:choose>
            <xsl:when test="not($field)">
                <!-- Done -->
                <xsl:value-of select="''"/>
            </xsl:when>
            <xsl:when test="$field/self::w:r[w:fldChar[@w:fldCharType='end']]">
                <!-- Done -->
                <xsl:value-of select="''"/>
            </xsl:when> 
            <xsl:when test="$field/w:instrText">
                <xsl:variable name="text-here" select="$field/w:instrText" as="xs:string"/>
                <xsl:variable name="text-next" select="pcm:build-field-private($field/following-sibling::w:r[1])" as="xs:string"/> 
                
                <xsl:value-of select="concat($text-here, $text-next)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="pcm:build-field-private($field/following-sibling::w:r[1])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="pcm:build-field" as="node()+">
        <xsl:param name="field" as="element()?"/>
        <xsl:variable name="field-as-string" select="pcm:build-field-private($field)" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="matches($field-as-string, ' *XE +.+')">
                <xsl:analyze-string select="translate(substring-after($field-as-string, 'XE'), '&quot;', '')"
                    regex="[^:]+">
                    <xsl:matching-substring>
                        <indexterm><xsl:value-of select="normalize-space(regex-group(0))"/></indexterm>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring/>
                </xsl:analyze-string>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$field-as-string"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="pcm:atRightmostColumn" as="xs:boolean">
        <xsl:param name="current-node" as="node()"/>
        <xsl:sequence select="exists($current-node/ancestor-or-self::w:tc[1][not(following-sibling::w:tc)])"/>
    </xsl:function>
    
    <xsl:function name="pcm:atLastRow" as="xs:boolean">
        <xsl:param name="current-node" as="node()"/>
        <xsl:sequence select="exists($current-node/ancestor-or-self::w:tr[1][not(following-sibling::w:tr)])"/>
    </xsl:function>
    
    <xsl:function name="pcm:cellShading" as="xs:string">
        <!-- Shading in table cell -->
        <xsl:param name="currentCell" as="element(w:tc)"/>
        <xsl:choose>
            <xsl:when test="$apply-table-backgrounds = 'yes'">
                <xsl:variable name="shading" select="$currentCell/w:tcPr/w:shd/@w:fill" as="xs:string?"/>
                <xsl:choose>
                    <xsl:when test="$shading != ''">
                        <xsl:value-of select="concat($outputclass-prefix, 'background-color_', $shading)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="''"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="''"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="pcm:getTableBordersElementFromStyledoc" as="element(w:tblBorders)?">
        <xsl:param name="nodeInsideTable" as="node()"/>
        
        <!-- The style in the style file (elsewhere in the DOCX-zip file) should match the tblStyle element
             in this table. -->
        
        <xsl:choose>
            <xsl:when test="exists($nodeInsideTable/ancestor-or-self::w:tbl[1]/w:tblPr/w:tblStyle/@w:val)">
                <xsl:variable name="tableStyleName" select="$nodeInsideTable/ancestor-or-self::w:tbl[1]/w:tblPr/w:tblStyle/@w:val" as="xs:string"/>
                <xsl:variable name="tblBorders"
                    select="$styledoc/w:styles/w:style[@w:type='table' and @w:styleId = $tableStyleName]/w:tblPr/w:tblBorders"
                    as="element(w:tblBorders)?"
                />
                
                <xsl:sequence select="$tblBorders"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- No matching table style in external style doc, return empty sequence: -->
                <xsl:sequence select="()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="pcm:getTableBordersElementFromTable" as="element(w:tblBorders)?">
        <xsl:param name="nodeInsideTable" as="node()"/>
        
        <xsl:variable name="tblBordersThisTable" select="$nodeInsideTable/ancestor-or-self::w:tbl/w:tblPr/w:tblBorders" as="element(w:tblBorders)?"/>
        
        <xsl:sequence select="$tblBordersThisTable"/>
    </xsl:function>
    
    <xsl:function name="pcm:tableDefinesBorder" as="xs:boolean">
        <!-- Check if the current table has a border-style element such as top, left, etc.. If so, return true if the value is not 'none' (else false).
             If there is no such element, do the same check for the border-style element in the styles document elsewhere in the DOCX-file.
             Otherwise, return false.
        -->
        <xsl:param name="nodeInsideTable" as="node()"/>
        <xsl:param name="elementLocalName" as="xs:string"/> <!-- Disregard the namespace, to make it simple (we are in the correct context) -->
        
        <xsl:variable name="localTblBorders" select="pcm:getTableBordersElementFromTable($nodeInsideTable)"/>
        <xsl:variable name="externalTblBorders" select="pcm:getTableBordersElementFromStyledoc($nodeInsideTable)"/>
        
        <xsl:choose>
            <xsl:when test="exists($localTblBorders/*[local-name() = $elementLocalName])">
                <xsl:sequence select="$localTblBorders/*[local-name() = $elementLocalName]/@w:val != 'none'"/>
            </xsl:when>
            <xsl:when test="exists($externalTblBorders/*[local-name() = $elementLocalName])">
                <xsl:sequence select="$externalTblBorders/*[local-name() = $elementLocalName]/@w:val != 'none'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="pcm:cellBorders" as="xs:string">
        <xsl:param name="currentCell" as="element(w:tc)"/>
        
        <xsl:choose>
            <xsl:when test="$apply-table-borders = 'yes'">
                <xsl:variable name="tcBorders" select="$currentCell/w:tcPr/w:tcBorders" as="element()?"/>
                
                <xsl:variable name="top" select="if ($tcBorders/w:top and not($tcBorders/w:top/@w:val='none')) then concat($outputclass-prefix, 'border-top-style_solid ') else ''"/>
                
                <xsl:variable name="left" select="if ($tcBorders/w:left and not($tcBorders/w:left/@w:val='none')) then concat($outputclass-prefix, 'border-left-style_solid ') else ''"/>
                
                <xsl:variable name="bottom" select="if ((pcm:tableDefinesBorder($currentCell, 'insideH') and not(pcm:atLastRow($currentCell))) or
                    ($tcBorders/w:bottom and not($tcBorders/w:bottom/@w:val='none'))) then concat($outputclass-prefix, 'border-bottom-style_solid ') else ''"/>
                
                <xsl:variable name="right" select="if ((pcm:tableDefinesBorder($currentCell, 'insideV') and not(pcm:atRightmostColumn($currentCell))) or
                    ($tcBorders/w:right and not($tcBorders/w:right/@w:val='none'))) then concat($outputclass-prefix, 'border-right-style_solid ') else ''"/>
                
                <xsl:variable name="aux1" select="normalize-space(concat($top, $left, $bottom, $right))"/>
                <xsl:variable name="aux2" select="if ($aux1 != '') then concat($aux1, ' ', $outputclass-prefix, 'border-collapse_collapse') else ''"/>
                
                <xsl:value-of select="$aux2"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="''"/>
            </xsl:otherwise>
        </xsl:choose> 
    </xsl:function>
    
    <xsl:function name="pcm:get-colnum" as="xs:integer">
        <xsl:param name="currentCell" as="element(w:tc)"/>
        <!-- Bij voorafgaande verticale overspanning die hoger begint dan de huidige rij, is er toch een (leeg) <w:tc> element. -->
        <xsl:value-of select="count($currentCell/preceding-sibling::w:tc[not(w:tcPr/w:gridSpan)]) +
            sum($currentCell/preceding-sibling::w:tc/w:tcPr/w:gridSpan/@ w:val) + 1"/>
    </xsl:function>
    
    <xsl:function name="pcm:count-span-rows" as="xs:integer">
        <xsl:param name="currentCell" as="element(w:tc)"/>
        <xsl:param name="colnum" as="xs:integer"/>
        
        <xsl:variable name="startRow" select="$currentCell/parent::w:tr/following-sibling::w:tr[1]" as="element(w:tr)?"/>
        
        <xsl:value-of select="1 + pcm:private-count-span-rows($startRow, $colnum)"/>
    </xsl:function>
    
    <xsl:function name="pcm:private-count-span-rows" as="xs:integer">
        <xsl:param name="currentRow" as="element(w:tr)?"/>
        <xsl:param name="colnum" as="xs:integer"/>
        
        <xsl:choose>
            <xsl:when test="not(exists($currentRow))">
                <xsl:value-of select="xs:integer(0)"/>
            </xsl:when>
            <xsl:when test="$currentRow/w:tc[position() = $colnum]/w:tcPr/w:vMerge[not(@w:val) or @w:val != 'restart']">
                <xsl:variable name="nextRow" select="$currentRow/following-sibling::w:tr[1]" as="element(w:tr)?"/>
                <xsl:value-of select="1 + pcm:private-count-span-rows($nextRow, $colnum)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="xs:integer(0)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template name="placenewline">
        <!-- New line op onschuldige plekken om heel erg lange regels te voorkomen... -->
        <xsl:value-of select="$NL"/>
    </xsl:template>
    
    <xsl:template match="rels:Relationships">
        <!-- Start the main convertion: -->
        <xsl:apply-templates select="$worddoc"/>
    </xsl:template>
    
    <xsl:template match="w:document" xmlns:uuid="java:java.util.UUID">
        <!-- TODO This uses an extension function which (for Saxon PE) requires a license. Perhaps pass the uuid via a parameter? -->
        <topic id="{concat('topic-', translate(uuid:randomUUID(), '-', '_'))}" xsl:exclude-result-prefixes="uuid">
            <title><?TODO Please supply a title?></title>
            <xsl:apply-templates select="w:body"/>
        </topic>
    </xsl:template>
    
    <xsl:template match="w:body">
        <xsl:variable name="stage1">
            <body>
                <section>
                    <xsl:apply-templates/>
                </section>
                <xsl:if test=".//w:footnoteReference">
                    <!-- Pull footnotes: -->
                    <section outputclass="{concat($outputclass-prefix, 'footnotes')}">
                        <title  outputclass="{concat($outputclass-prefix, 'notes-title')}"><xsl:value-of select="$noten-titel"></xsl:value-of></title>
                        <xsl:apply-templates select=".//w:footnoteReference" mode="footnotepull"/>
                    </section>
                    <xsl:call-template name="placenewline"/>
                </xsl:if>
                <xsl:call-template name="placenewline"/>
            </body>
        </xsl:variable>
        
        <!--<xsl:message>Denk aan /tmp/klad.xml!</xsl:message>
        <xsl:result-document href="/tmp/klad.xml"><xsl:copy-of select="$stage1"/></xsl:result-document>-->
        
        <xsl:apply-templates select="$stage1" mode="stage2"/>
    </xsl:template>
    
    <xsl:template match="w:p">
        <xsl:variable name="style" select="pcm:lookupParagraphStyleName(w:pPr/w:pStyle/@w:val)"/>

        <xsl:choose>
            <xsl:when test="parent::w:body and matches($style, 'heading_[1-9]')">
                <!-- Make it a section title with an outputclass: -->
                <title outputclass="{concat($outputclass-prefix, 'heading_', substring-after($style, '_'))}">
                    <xsl:attribute name="id" select="concat('toc.', generate-id())"/>
                    <xsl:apply-templates select="w:r"/>
                </title>
            </xsl:when>
            <xsl:when test="w:pPr/w:pStyle[@w:val=$stylename-fullpageimage] and w:r/w:drawing">
                <!-- Special treatment if the paragraph has this style and contains an image - it is a image that needs to fill the
                     entire page: -->
                <p outputclass="{concat($outputclass-prefix, 'fullpageimage')}"><xsl:apply-templates select="w:r/w:drawing"/></p>
            </xsl:when>
            <xsl:when test="w:pPr[w:pStyle[@w:val='ListParagraph'] and w:numPr/w:numId]">
                <!-- List item. List containers are not in the document, they have to be added in a later stage. -->
                <xsl:variable name="numPr" select="w:pPr/w:numPr" as="element()"/>
                <xsl:variable name="numIdElement" select="w:pPr/w:numPr/w:numId" as="element(w:numId)"/>
                <xsl:variable name="numval" select="$numIdElement/@w:val"/>
                <xsl:variable name="numid" select="$numIdElement/@w:val"/>
                <xsl:variable name="ilvl" select="$numPr/w:ilvl/@w:val"/>
                
                <!-- No startnum in Dita
                <xsl:variable name="abstractNumId" select="$numberingdoc/w:numbering/w:num[@w:numId=$numid]/w:abstractNumId/@w:val"/>
                <xsl:variable name="startNum" select="$numberingdoc/w:numbering/w:abstractNum[@w:abstractNumId=$abstractNumId]/w:lvl[@w:ilvl=$ilvl]/w:start/@w:val"/>
                -->
                <li numid="{$numval}" level="{$ilvl}"
                    outputclass="{pcm:lookupListStyleName($numIdElement/@w:val, $ilvl)}"
                    > <!-- startnum="{$startNum}" -->
                    <p><xsl:apply-templates select="w:r"/></p>
                </li>
            </xsl:when>
            <xsl:otherwise>
                <!-- Styles that we don't know are considered standard (Standaard), but we store the original name as well: --> 
                <p outputclass="{normalize-space(concat($outputclass-prefix, 'standard ', $style))}"><xsl:apply-templates select="w:r"/></p>
                <xsl:call-template name="placenewline"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="match-text">
        <xsl:apply-templates select="w:t|w:footnoteReference|w:footnoteRef|w:drawing|w:br"/>
        <xsl:variable name="begin-field" select="following-sibling::*[1]/self::w:r[w:fldChar[@w:fldCharType='begin']]" as="element()?"/>
        <xsl:if test="$begin-field">
            <xsl:sequence select="pcm:build-field($begin-field)"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="w:r[not(w:rPr) or w:rPr[not(*)]]">
        <xsl:call-template name="match-text"/>
    </xsl:template>
    
    <xsl:template match="w:r[w:rPr/*]">
        <xsl:variable name="ph">
            <ph>
                <xsl:apply-templates select="w:rPr"/>
                <xsl:call-template name="match-text"/>
            </ph>
        </xsl:variable>
        
        <xsl:if test="$ph != '' or ($ph//img)">
           <xsl:apply-templates select="$ph" mode="replace-ph"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="w:rPr">
        <xsl:variable name="boldstyle" select="if (w:b) then concat($outputclass-prefix, 'font-weight_bold ') else ''"/>
        <xsl:variable name="italicstyle" select="if (w:i) then concat($outputclass-prefix, 'font-style_italic ') else ''"/>
        <xsl:variable name="underlinestyle" select="if (w:u) then concat($outputclass-prefix, 'text-decoration_underline ') else ''"/>
        <xsl:variable name="superscriptstyle" select="if (w:vertAlign/@w:val='superscript') then concat($outputclass-prefix, 'vertical-align_super ') else ''"/>
        <xsl:variable name="subscriptstyle" select="if (w:vertAlign/@w:val='subscript') then concat($outputclass-prefix, 'vertical-align_sub ') else ''"/>
        <xsl:variable name="colorstyle" select="if (w:color) then concat($outputclass-prefix, 'color_', w:color/@w:val, ' ') else ''"/>
        <xsl:variable name="highlight" select="if (w:highlight) then concat($outputclass-prefix, 'background-color_', w:highlight/@w:val, ' ') else ''"/>
        
        <xsl:variable name="style" select="normalize-space(concat($boldstyle, $italicstyle, $underlinestyle, $superscriptstyle, $subscriptstyle, $colorstyle, $highlight))"/>
        
        <xsl:variable name="aux1" select="w:rStyle/@w:val"/>
        <xsl:variable name="aux2" select="if ($aux1 != '') then pcm:lookupCharactereStyleName($aux1) else ''"/>
        <xsl:variable name="outputclass" select="normalize-space(concat($aux2, ' ', $style))"/>
        
        <xsl:if test="$outputclass != ''">
            <!-- Note: many of the style names in @outputclass will later be replaced by Dita elements like <b>, <i> and <sup> -->
            <xsl:attribute name="outputclass" select="$outputclass"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="ph[not(@*)]" mode="replace-ph">
        <!-- Leave out the ph element -->
        <xsl:apply-templates mode="replace-ph"/>
    </xsl:template>
    
    <xsl:template match="ph[@outputclass]" mode="replace-ph">
        <xsl:variable name="new-output-class" select="normalize-space(
            replace(@outputclass, concat($outputclass-prefix, '(font-weight_bold|font-style_italic|text-decoration_underline|vertical-align_super|vertical-align_sub)'), ''))"/>
        <xsl:choose>
            <xsl:when test="$new-output-class != ''">
                <ph outputclass="{$new-output-class}">
                    <xsl:call-template name="replace-ph"><xsl:with-param name="outputclass" select="@outputclass"/></xsl:call-template>
                </ph>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="replace-ph"><xsl:with-param name="outputclass" select="@outputclass"/></xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="@* | node()" mode="replace-ph">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="replace-ph"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template name="replace-ph">
        <xsl:param name="outputclass" required="yes"/>
        <xsl:choose>
            <xsl:when test="contains($outputclass, concat($outputclass-prefix, 'font-weight_bold'))">
                <b>
                    <xsl:call-template name="replace-ph">
                        <xsl:with-param name="outputclass" select="replace($outputclass, concat($outputclass-prefix, 'font-weight_bold'), '')"/>
                    </xsl:call-template>
                </b>
            </xsl:when>
            <xsl:when test="contains($outputclass, concat($outputclass-prefix, 'font-style_italic'))">
                <i>
                    <xsl:call-template name="replace-ph">
                        <xsl:with-param name="outputclass" select="replace($outputclass, concat($outputclass-prefix, 'font-style_italic'), '')"/>
                    </xsl:call-template>
                </i>
            </xsl:when>
            <xsl:when test="contains($outputclass, concat($outputclass-prefix, 'text-decoration_underline'))">
                <u>
                    <xsl:call-template name="replace-ph">
                        <xsl:with-param name="outputclass" select="replace($outputclass, concat($outputclass-prefix, 'text-decoration_underline'), '')"/>
                    </xsl:call-template>
                </u>
            </xsl:when>
            <xsl:when test="contains($outputclass, concat($outputclass-prefix, 'vertical-align_super'))">
                <sup>
                    <xsl:call-template name="replace-ph">
                        <xsl:with-param name="outputclass" select="replace($outputclass, concat($outputclass-prefix, 'vertical-align_super'), '')"/>
                    </xsl:call-template>
                </sup>
            </xsl:when>
            <xsl:when test="contains($outputclass, concat($outputclass-prefix, 'vertical-align_sub'))">
                <sub>
                    <xsl:call-template name="replace-ph">
                        <xsl:with-param name="outputclass" select="replace($outputclass, concat($outputclass-prefix, 'vertical-align_sub'), '')"/>
                    </xsl:call-template>
                </sub>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="@* | node()" mode="replace-ph"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="w:br">
        <!-- TODO Dita has no br. Do something fuzzy with p elements? -->
        <ph outputclass="{concat($outputclass-prefix, 'br')}"/>
    </xsl:template>
    
    <xsl:template match="w:drawing">
        <xsl:variable name="imageFileName" select="pcm:determine-image-file-name(.//pic:cNvPr[1])"/>
        <image src="{$imageFileName}" alt="-">
            <xsl:if test="ancestor::w:p[1]/w:pPr/w:pStyle[@w:val=$stylename-fullpageimage]">
                <xsl:attribute name="outputclass" select="concat($outputclass-prefix, 'fullpageimage')"></xsl:attribute>
            </xsl:if>
        </image>
    </xsl:template>
    
    <xsl:template match="w:footnoteReference">
        <!-- w:footnoteReference is in the main document. -->
        <ph outputclass="{concat($outputclass-prefix, 'footnoteNum')}">
            <!-- TODO Check the format of anchors -->
            <xref id="{concat($FOOTNOTEBACKPREFIX, generate-id())}" href="{concat('#', $FOOTNOTEPREFIX, generate-id())}"><xsl:number/></xref>
        </ph>
    </xsl:template>
    
    <xsl:template match="w:footnoteReference" mode="footnotepull">
        <xsl:variable name="id" select="generate-id()" as="xs:string"/>
        <sectiondiv outputclass="{concat($outputclass-prefix, 'footnote')}">
            <xsl:variable name="fnid" select="@w:id" as="xs:string"/>
            <xsl:apply-templates select="$footnotedoc/w:footnotes/w:footnote[@w:id = $fnid]/*">
                <xsl:with-param name="id" select="$id" tunnel="yes" as="xs:string"/>
            </xsl:apply-templates>
        </sectiondiv>
        <xsl:call-template name="placenewline"/>
    </xsl:template>
    
    <xsl:template match="w:footnoteRef">
        <!-- w:footnoteRef is in the footnotes document. -->
        <xsl:param name="id" required="yes" tunnel="yes"/>
        <ph outputclass="{concat($outputclass-prefix, 'footnoteNum')}">
            <xref href="{concat('#', $FOOTNOTEBACKPREFIX, $id)}" id="{concat($FOOTNOTEPREFIX, $id)}"><xsl:number/></xref>
        </ph>
    </xsl:template>
    
    <xsl:template match="w:tbl">
        <table>
            <tgroup cols="{count(w:tblGrid/w:gridCol)}">
                <!-- Generate a style attribute for any borders. Note that this currently excludes any other style properties. -->
                <xsl:call-template name="doTableBorders"/>

                <!--<xsl:variable name="sum-grid-cols" select="pcm:sum-grid-cols(w:tblGrid)"/>-->
                <xsl:for-each select="w:tblGrid/w:gridCol">
                    <xsl:variable name="width" select="xs:integer(round(@w:w div 100))" as="xs:integer"/>
                    <colspec colname="{concat('c', position())}" colnum="{position()}" colwidth="{$width}*"/>
                </xsl:for-each>
                <xsl:if test="w:tr/w:trPr/w:tblHeader">
                    <!-- Aanname: header regels staan aan het begin van de tabel, niet halverwege -->
                    <thead>
                        <xsl:apply-templates select="w:tr[w:trPr/w:tblHeader]"/>
                    </thead>
                </xsl:if>
                <tbody>
                    <xsl:choose>
                        <xsl:when test="w:tr[not(w:trPr/w:tblHeader)]">
                            <xsl:apply-templates select="w:tr[not(w:trPr/w:tblHeader)]"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <row>
                                <entry><p><xsl:value-of select="pcm:errormessage('table without body encountered')"/></p></entry>
                            </row>
                        </xsl:otherwise>
                    </xsl:choose>
                </tbody>
            </tgroup>
        </table>
    </xsl:template>
    
    <xsl:template name="doTableBorders">
        <xsl:if test="$apply-table-borders = 'yes'">
            <xsl:variable name="top" select="if (pcm:tableDefinesBorder(., 'top')) then 'border-top-style_solid; ' else ''"/>
            <xsl:variable name="left" select="if (pcm:tableDefinesBorder(., 'left')) then 'border-left-style_solid; ' else ''"/>
            <xsl:variable name="bottom" select="if (pcm:tableDefinesBorder(., 'bottom')) then 'border-bottom-style_solid; ' else ''"/>
            <xsl:variable name="right" select="if (pcm:tableDefinesBorder(., 'right')) then 'border-right-style_solid; ' else ''"/>
            
            <xsl:variable name="aux" select="normalize-space(concat($top, $left, $bottom, $right))"/>
            <xsl:variable name="style" select="if ($aux != '') then concat($aux, ' border-collapse_collapse;') else ''"/>
            
            <xsl:if test="$style != ''">
                <xsl:attribute name="style" select="$style"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="w:tr">
        <row>
            <!-- Leaving out formatting properties of the row -->
            <xsl:apply-templates select="w:tc"/>
        </row>
        <xsl:call-template name="placenewline"/>
    </xsl:template>
    
    <xsl:template match="w:tc">
        <!-- Een verticale span begint bij w:tcPr/w:vMerge met @w:val="restart". De onderliggende cellen zijn leeg,
             en worden gekenmerkt door w:tcPr/w:vMerge zonder @w:val-attribuut. -->
        <xsl:if test="not(w:tcPr/w:vMerge) or w:tcPr/w:vMerge[@w:val = 'restart']">
            <entry>
                <!-- Leaving out most formatting properties of the cell -->
                
                <!-- Generate style attribute if shading or borders supplied. Note that this currently excludes any other style properties. -->
                <xsl:variable name="shading" as="xs:string" select="pcm:cellShading(.)"/>
                <xsl:variable name="borders" as="xs:string" select="pcm:cellBorders(.)"/>
                
                <xsl:variable name="style" select="normalize-space(concat($shading, $borders))"/>
                <xsl:if test="$style != ''">
                    <xsl:attribute name="style" select="$style"/>
                </xsl:if>
                
                <xsl:if test="w:tcPr/w:gridSpan/@w:val != ''">
                    <xsl:variable name="colnum" select="pcm:get-colnum(.)"/>
                    <xsl:attribute name="namest" select="concat('c', $colnum)"/>
                    <xsl:attribute name="nameend" select="concat('c', $colnum + (w:tcPr/w:gridSpan/@w:val - 1))"/>
                </xsl:if>
                
                <xsl:if test="w:tcPr/w:vMerge/@w:val = 'restart'">
                    <xsl:variable name="colnum" select="position()"/>
                    <xsl:attribute name="morerows" select="pcm:count-span-rows(., $colnum) - 1"/>
                </xsl:if>
                
                <xsl:apply-templates select="*[not(self::w:tcPr)]"/>
            </entry>
            <xsl:call-template name="placenewline"/>
        </xsl:if>        
    </xsl:template>
    
    <!-- Stage 2 templates: -->
    <xsl:function name="pcm:ulOrOl" as="xs:string">
        <xsl:param name="outputclass" as="xs:string"/>
        <xsl:value-of select="if ($outputclass = 'bullet') then 'ul' else 'ol'"/>
    </xsl:function>
    
    <xsl:function name="pcm:nextListItem" as="element(li)?">
        <xsl:param name="currentLi" as="element(li)"/>
        <xsl:sequence select="$currentLi/following-sibling::*[1][self::li]"/>
    </xsl:function>
    
    <xsl:function name="pcm:previousListItem" as="element(li)?">
        <xsl:param name="currentLi" as="element(li)"/>
        <xsl:sequence select="$currentLi/preceding-sibling::*[1][self::li]"/>
    </xsl:function>
    
    <xsl:function name="pcm:findFirstItemBeyondNestedList" as="element(li)?">
        <!-- At the toplevel call of this recursive function, the listItem parameter should reference the first item of the nested list.
             The function returns the list item that comes after the nested list (if it can be found; otherwise, the empty sequence is returned.
             The item beyond the nested list is identified by having the same numid and level as given by the parameters. If a non-matching
             numid is encountered, searching stops and an empty sequence is returned.
        -->
        <xsl:param name="listItem" as="element(li)"/>
        <xsl:param name="requiredNumid" as="xs:string"/>
        <xsl:param name="requiredLevel" as="xs:integer"/>
        
        <xsl:choose>
            <xsl:when test="$listItem and $listItem/@numid = $requiredNumid">
                <xsl:choose>
                    <xsl:when test="xs:integer($listItem/@level) gt $requiredLevel">
                        <!-- Still at a nested list, or at an even deeper nested one. -->
                        <xsl:sequence select="pcm:findFirstItemBeyondNestedList(pcm:nextListItem($listItem), $requiredNumid, $requiredLevel)"/> 
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
    
    <xsl:function name="pcm:list-style-type" as="xs:string">
        <xsl:param name="outputclass" as="xs:string"/>
        <xsl:param name="level" as="xs:integer"/>
        <xsl:choose>
            <xsl:when test="$outputclass = 'bullet'">
                <xsl:value-of select="concat('list-style-type_', if (($level mod 2) = 1) then 'disc' else 'circle')"/>
            </xsl:when>
            <xsl:when test="$outputclass = 'decimal'">
                <xsl:value-of select="'list-style-type_decimal'"/>
            </xsl:when>
            <xsl:when test="$outputclass = 'lowerLetter'">
                <xsl:value-of select="'list-style-type_lower-alpha'"/>
            </xsl:when>
            <xsl:when test="$outputclass = 'upperLetter'">
                <xsl:value-of select="'list-style-type_upper-alpha'"/>
            </xsl:when>
            <xsl:when test="$outputclass = 'lowerRoman'">
                <xsl:value-of select="'list-style-type_lower-roman'"/>
            </xsl:when>
            <xsl:when test="$outputclass = 'upperRoman'">
                <xsl:value-of select="'list-style-type_upper-roman'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$outputclass"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template match="@*|node()" mode="stage2">
        <xsl:copy><xsl:apply-templates select="@*|node()" mode="stage2"/></xsl:copy>
    </xsl:template>
    
    <xsl:template name="doStartAttributeOrProcessingInstruction">
        <!-- Since this may generate an attribute or a processing instruction (depending on the value of stylesheet parameter allow-ol-start-attribute),
             make sure this template is called after all other attributes have been processed.
        -->
        <xsl:param name="listItem" as="element(li)"/>
        <xsl:param name="ulOrOl" as="xs:string"/>
        
        <xsl:if test="$ulOrOl = 'ol'">
            <xsl:variable name="currentNumId" select="$listItem/@numid"/>
            <xsl:variable name="currentLevel" select="$listItem/@level"/>
            
            <xsl:variable name="start">
                <xsl:choose>
                    <xsl:when test="pcm:previousListItem($listItem)[@numid = $currentNumId and @level = $currentLevel]">
                        <xsl:value-of select="$listItem/@startnum + count($listItem/preceding-sibling::li[@numid = $currentNumId and $listItem/@level = $currentLevel])"/>
                    </xsl:when>
                    <xsl:when test="$listItem/@startnum != 1">
                        <xsl:value-of select="$listItem/@startnum"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="''"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <xsl:choose>
                <xsl:when test="$start = ''"/>
                
                <!--<xsl:when test="$allow-ol-start-attribute = 'yes'">
                    <xsl:attribute name="start" select="$start"/>
                </xsl:when>-->
                
                <xsl:otherwise>
                    <xsl:processing-instruction name="ol-start"><xsl:value-of select="$start"/></xsl:processing-instruction>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="li[not(pcm:previousListItem(.)) or (pcm:previousListItem(.)/@numid != @numid)]" mode="stage2">
        <xsl:call-template name="doList">
            <xsl:with-param name="listItem" select="."/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="li[pcm:previousListItem(.)]" mode="stage2"/> <!-- Non-first list item is pulled, not pushed -->
    
    <xsl:template name="doList">
        <xsl:param name="listItem" as="element(li)" required="yes"/>
        
        <xsl:variable name="ulOrOl" select="pcm:ulOrOl($listItem/@outputclass)"/>
        <xsl:element name="{$ulOrOl}">
            <xsl:attribute name="outputclass" select="@outputclass"/>
            <xsl:variable name="list-style-type" select="pcm:list-style-type($listItem/@outputclass, $listItem/@level)"/>
            <xsl:if test="$list-style-type != ''">
                <xsl:attribute name="outputclass" select="$list-style-type"/>
            </xsl:if>
            <xsl:call-template name="doStartAttributeOrProcessingInstruction">
                <xsl:with-param name="listItem" select="$listItem"/>
                <xsl:with-param name="ulOrOl" select="$ulOrOl"/>
            </xsl:call-template>
            <xsl:call-template name="doListItems"><xsl:with-param name="listItem" select="$listItem"/></xsl:call-template>
        </xsl:element>
    </xsl:template>
    
    <xsl:template name="doListItems">
        <xsl:param name="listItem" as="element(li)" required="yes"/>
        
        <xsl:variable name="nextListItem" select="pcm:nextListItem($listItem)" as="element(li)?"/>
        <xsl:variable name="nestedListFollows" select="$nextListItem and ($nextListItem/@numid = $listItem/@numid) and ($nextListItem/@level gt $listItem/@level)" as="xs:boolean"/>
        
        <xsl:for-each select="$listItem"> <!-- One  iteration only -->
            <xsl:copy>
                <xsl:apply-templates select="@*|node()" mode="stage2"/>
                
                <xsl:if test="$nestedListFollows">
                    <xsl:call-template name="doList"><xsl:with-param name="listItem" select="$nextListItem"/></xsl:call-template>
                </xsl:if>
            </xsl:copy>
            
            <!-- Deal with the rest of the list, if any -->
            <xsl:choose>
                <xsl:when test="$nestedListFollows">
                    <!-- Continue beyond the nested list: -->
                    <xsl:variable name="firstItemBeyondNestedList" select="pcm:findFirstItemBeyondNestedList($nextListItem, @numid, @level)" as="element(li)?"/>
                    <xsl:if test="$firstItemBeyondNestedList">
                        <xsl:call-template name="doListItems"><xsl:with-param name="listItem" select="$firstItemBeyondNestedList"/></xsl:call-template>
                    </xsl:if>
                </xsl:when>
                
                <xsl:when test="$nextListItem/@numid != $listItem/@numid"/> <!-- Here starts a new list, rely on the match-template for this situation. -->
                
                <xsl:when test="$nextListItem/@level = $listItem/@level">
                    <!-- Same numid, same level, so same list. -->
                    <xsl:call-template name="doListItems"><xsl:with-param name="listItem" select="$nextListItem"/></xsl:call-template>
                </xsl:when>
                
                <xsl:otherwise>
                    <!-- Same numid, lower level, so end of the nested list (note that the higher level is already dealt with, because $nestedListFollows is true in that case). -->
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        
    </xsl:template>
    
    <xsl:template match="li/@level | li/@outputclass | li/@numid | li/@startnum" mode="stage2"/>
    
</xsl:stylesheet>