<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"
    xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:pcm="http://www.masereeuw.nl/xslt/3.0/functions" xmlns:rels="http://schemas.openxmlformats.org/package/2006/relationships"
    xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:xlink="http://www.w3.org/1999/xlink" exclude-result-prefixes="xs w pic wp a pcm rels r o" expand-text="yes" version="3.0">

    <!-- Result language. If absent, try to find it in the document. -->
    <xsl:param name="language-code" as="xs:string" select="''"/>
    <!-- Prefix for generated style names; note: do not use characters that need to be escaped in a regex -->
    <xsl:param name="style-prefix" select="'PCM-'"/>

    <xsl:param name="style-bookmark" select="concat($style-prefix, 'word_bookmark')"/>

    <xsl:param name="notes-title" select="'Notes'" as="xs:string"/>

    <!-- apply-table-borders: if 'yes', do a conversion of DOCX table borders to CSS border styles -->
    <xsl:param name="apply-table-borders" select="'yes'"/>

    <!-- apply-table-backgrounds: if 'yes', do a conversion of DOCX table shading to CSS background-color styles -->
    <xsl:param name="apply-table-backgrounds" select="'no'"/>

    <!-- Specify 'yes' for absolute table column width (taken from Word) or 'no' for relative ones (percentages). -->
    <xsl:param name="absolute-table-column-width" select="'no'"/>

    <xsl:param name="word-to-inch-divisor-for-tables" select="1400" as="xs:integer"/>

    <xsl:output method="xml" indent="no"/>

    <xsl:key name="bookmarks" match="w:bookmarkStart" use="@w:name"/>

    <!-- Note: The input document is the _rels/rels file that points to the word/document.xml file (or whatever its name will be) -->
    <xsl:variable name="worddocfile" select="
            concat('../',
            /rels:Relationships/rels:Relationship[@Type = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument']/@Target)" as="xs:string"/>
    <xsl:variable name="worddoc" select="doc(resolve-uri($worddocfile, base-uri(/)))"/>

    <xsl:variable name="documentrelsfile" select="resolve-uri('_rels/document.xml.rels', base-uri($worddoc))"/>
    <xsl:variable name="documentrelsdoc" select="doc($documentrelsfile)"/>

    <xsl:variable name="stylefile" select="$documentrelsdoc/rels:Relationships/rels:Relationship[@Type = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles']/@Target"/>
    <xsl:variable name="styledoc" select="doc(resolve-uri($stylefile, base-uri($worddoc)))"/>

    <xsl:variable name="numberingfile" select="$documentrelsdoc/rels:Relationships/rels:Relationship[@Type = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering']/@Target"/>
    <xsl:variable name="numberingdoc" select="doc(resolve-uri($numberingfile, base-uri($worddoc)))"/>

    <!-- If there are no footnotes, the documentrelsdoc does not contain a reference to a footnotes document. However, all seems
         to go well if this happens.
    -->
    <xsl:variable name="footnotefile" select="$documentrelsdoc/rels:Relationships/rels:Relationship[@Type = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/footnotes']/@Target"/>
    <xsl:variable name="footnotedoc" select="doc(resolve-uri($footnotefile, base-uri($worddoc)))"/>

    <xsl:variable name="FOOTNOTEPREFIX" select="'vn.'"/>
    <xsl:variable name="FOOTNOTEBACKPREFIX" select="concat('back.', $FOOTNOTEPREFIX)"/>

    <xsl:variable name="NL" select="'&#10;'"/>
    
    <!-- Stylenames (from the Word styles document, but normalized (e.g., spaces to underscore, lower case) that
         indicate that we are dealing with a list:
    -->
    <xsl:variable name="list-style-names" as="xs:string+" select="('list_unordered', 'list_arabic', 'list_arabic_continued', 'listbullet', 'list_bullet', 'list_number')"/>

    <xsl:function name="pcm:errormessage" as="xs:string">
        <xsl:param name="message" as="xs:string"/>
        <xsl:variable name="errormessage" select="concat('*', $message, '*')"/>
        <xsl:message>
            <xsl:value-of select="$errormessage"/>
        </xsl:message>
        <xsl:value-of select="$errormessage"/>
    </xsl:function>

    <xsl:function name="pcm:extension-from-filename" as="xs:string">
        <xsl:param name="filename" as="xs:string"/>
        <xsl:variable name="extension" select="lower-case(replace($filename, '^.*\.([^./]+)$', '$1'))"/>
        <xsl:choose>
            <xsl:when test="$extension eq 'jpg'">
                <xsl:value-of select="'image/jpeg'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'image/' || $extension"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="pcm:replaceFunnyCharacters" as="xs:string">
        <xsl:param name="string"/>
        <xsl:value-of select="lower-case(replace($string, ' ', '_'))"/>
    </xsl:function>

    <xsl:function name="pcm:lookupListStyleType" as="xs:string">
        <xsl:param name="numid"/>
        <xsl:param name="ilvl"/>
        <xsl:variable name="abstractNumId" select="$numberingdoc/w:numbering/w:num[@w:numId = $numid]/w:abstractNumId/@w:val"/>
        <xsl:variable name="numFmt" select="$numberingdoc/w:numbering/w:abstractNum[@w:abstractNumId = $abstractNumId]/w:lvl[@w:ilvl = $ilvl]/w:numFmt/@w:val"/>

        <!--<xsl:message><xsl:value-of select="concat('lookupListStyleType, numid=', $numid, ', ilvl=', $ilvl, ', abstractNumId=', $abstractNumId, ', numFmt=', $numFmt)"/></xsl:message>-->
        <xsl:value-of select="pcm:replaceFunnyCharacters($numFmt)"/>
    </xsl:function>

    <xsl:function name="pcm:lookupCharactereStyleName" as="xs:string">
        <xsl:param name="styleid"/>
        <xsl:value-of select="pcm:replaceFunnyCharacters($styledoc/w:styles/w:style[@w:type = 'character' and @w:styleId = $styleid]/w:name/@w:val)"/>
    </xsl:function>

    <xsl:function name="pcm:determine-image-file-name" as="xs:string">
        <xsl:param name="blipElement" as="element(a:blip)?"/>
        <xsl:variable name="pathname">
            <xsl:choose>
                <xsl:when test="not($blipElement)">
                    <xsl:value-of select="pcm:errormessage('missing blipElement element for image')"/>
                </xsl:when>
                <xsl:when test="not($blipElement/@r:link)">
                    <xsl:value-of select="pcm:errormessage('missing r:link-attribute element for image')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="wantedId" select="$blipElement/@r:link" as="xs:string"/>
                    <xsl:value-of select="$documentrelsdoc/rels:Relationships/rels:Relationship[@Id = $wantedId]/@Target"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- Since all images have been copied locally in the same folder as the result files, we can strip the path from the file name: -->
        <xsl:variable name="path-with-slashes" select="translate($pathname, '\', '/')"/>
        <xsl:value-of select="
                if (contains($path-with-slashes, '/')) then
                    replace($path-with-slashes, '^.*/([^/]+)$', '$1')
                else
                    $path-with-slashes"/>
    </xsl:function>

    <xsl:function name="pcm:build-field-private" as="xs:string">
        <xsl:param name="field" as="element()?"/>
        <xsl:choose>
            <xsl:when test="not($field)">
                <!-- Done -->
                <xsl:value-of select="''"/>
            </xsl:when>
            <xsl:when test="$field/self::w:r[w:fldChar[@w:fldCharType = 'end']]">
                <!-- Done -->
                <xsl:value-of select="''"/>
            </xsl:when>
            <xsl:when test="$field/w:instrText">
                <xsl:variable name="text-here" select="$field/w:instrText" as="xs:string"/>
                <xsl:variable name="text-next" select="pcm:build-field-private($field/following-sibling::w:r[1])" as="xs:string"/>
                <xsl:value-of select="concat($text-here, $text-next)"/>
            </xsl:when>
            <xsl:when test="$field/w:t">
                <xsl:variable name="text-here" select="$field/w:t" as="xs:string"/>
                <xsl:variable name="text-next" select="pcm:build-field-private($field/following-sibling::w:r[1])" as="xs:string"/>
                <xsl:value-of select="concat($text-here, $text-next)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="pcm:build-field-private($field/following-sibling::w:r[1])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="pcm:build-field-text" as="xs:string">
        <xsl:param name="field" as="element()?"/>
        <xsl:choose>
            <xsl:when test="not($field)">
                <!-- Done -->
                <xsl:value-of select="''"/>
            </xsl:when>
            <xsl:when test="$field/self::w:r[w:fldChar[@w:fldCharType = 'end']]">
                <!-- Done -->
                <xsl:value-of select="''"/>
            </xsl:when>
            <xsl:when test="$field/w:instrText">
                <xsl:value-of select="pcm:build-field-text($field/following-sibling::w:r[1])"/>
            </xsl:when>
            <xsl:when test="$field/w:t">
                <xsl:variable name="text-here" select="$field/w:t" as="xs:string"/>
                <xsl:variable name="text-next" select="pcm:build-field-private($field/following-sibling::w:r[1])" as="xs:string"/>
                <xsl:value-of select="concat($text-here, $text-next)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="text-here" select="$field" as="xs:string"/>
                <xsl:variable name="text-next" select="pcm:build-field-text($field/following-sibling::w:r[1])" as="xs:string"/>
                <xsl:value-of select="concat($text-here, $text-next)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="pcm:build-field" as="node()+">
        <xsl:param name="field" as="element()?"/>
        <xsl:variable name="field-as-string" select="pcm:build-field-private($field)" as="xs:string"/>

        <xsl:choose>
            <xsl:when test="matches($field-as-string, ' *XE +.+')">
                <xsl:analyze-string select="translate(substring-after($field-as-string, 'XE'), '&quot;', '')" regex="[^:]+">
                    <xsl:matching-substring>
                        <indexterm>
                            <xsl:value-of select="normalize-space(regex-group(0))"/>
                        </indexterm>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring/>
                </xsl:analyze-string>
            </xsl:when>
            <xsl:when test="matches($field-as-string, ' *SEQ +.+')">
                <!-- We ignore SEQ and we copy the numbers generated by Word -->
                <xsl:variable name="text" select="replace($field-as-string, '.*([0-9]+)$', '$1')"/>
                <xsl:variable name="seqtype" select="lower-case(replace($field-as-string, '^ *SEQ +([^ ]+).*$', '$1'))" as="xs:string?"/>
                <styled-content style="{concat($style-bookmark, ' ', $style-prefix, 'id-', $seqtype)}">
                    <xsl:value-of select="$text"/>
                </styled-content>

                <!--<xsl:value-of select="''"/>-->
            </xsl:when>
            <xsl:when test="matches($field-as-string, ' *REF [^ ]+')">
                <!-- Sample input:  REF _Ref387926700 \h  \* MERGEFORMAT
                     Regex group 1 wil; contains the number that identifies the xross reference: _Ref387926700.
                     The xrefType will contain information about the type of the xref: a table or a figure.
                -->
                <xsl:variable name="refid" as="xs:string" select="replace($field-as-string, ' *REF ([^ ]+).*', '$1')"/>
                <xsl:variable name="xrefType" select="$field/pcm:get-xref-type(key('bookmarks', $refid))"/>
                <xref href="{concat('#', pcm:normalize-bookmark-id($refid))}">
                    <styled-content style="{concat($style-prefix, 'xreftext ', $style-prefix, 'ref-', $xrefType)}">
                        <xsl:value-of select="pcm:build-field-text($field)"/>
                    </styled-content>
                </xref>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$field-as-string"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="pcm:get-xref-type" as="xs:string">
        <xsl:param name="bookmark" as="element(w:bookmarkStart)?"/>
        <!-- There are two bookmark constructions in Word:
            1.
            <w:bookmarkStart w:name="_Ref343521520" w:id="2"/>
            ..
            <w:r>
                <w:instrText xml:space="preserve"> SEQ Figure \* ARABIC </w:instrText>
            </w:r>
            ..
            <w:bookmarkEnd w:id="1"/>
            2.
            <w:bookmarkStart w:name="_Ref379962248" w:id="5"/>
           ..
            <w:fldSimple w:instr=" SEQ Table \* ARABIC ">
                <w:r>
                    <w:rPr>
                        <w:noProof/>
                    </w:rPr>
                    <w:t>2</w:t>
                </w:r>
            </w:fldSimple>
            <w:bookmarkEnd w:id="5"/>
            
            Note that bookmarks may be mixed (not even nested - check the ids:
                        <w:bookmarkStart w:name="_Ref343521538" w:id="1"/>
            <w:bookmarkStart w:name="_Ref343521520" w:id="2"/>
            <w:r>
                <w:t xml:space="preserve">Figure </w:t>
            </w:r>
            ..
            <w:r>
                <w:instrText xml:space="preserve"> SEQ Figure \* ARABIC </w:instrText>
            </w:r>
            ..
            <w:r w:rsidRPr="004E53BF">
                <w:fldChar w:fldCharType="end"/>
            </w:r>
            <w:bookmarkEnd w:id="1"/>
            ..
            <w:r w:rsidR="00DE1032">
                <w:t>Fuel injection system l</w:t>
            </w:r>
            <w:r w:rsidRPr="002C73D8">
                <w:t>ayout</w:t>
            </w:r>
            <w:bookmarkEnd w:id="2"/>

        -->
        <xsl:variable name="seqaux" select="string($bookmark/following-sibling::w:r/w:instrText[matches(text(), ' *SEQ +.+')][1])" as="xs:string?"/>
        <xsl:variable name="seq" select="
                if ($seqaux) then
                    $seqaux
                else
                    $bookmark/following-sibling::w:fldSimple[matches(@w:instr, ' *SEQ +.+')][1]/@w:instr" as="xs:string?"/>
        <xsl:value-of select="lower-case(replace($seq, '^ *SEQ +([^ ]+).*$', '$1'))"/>
    </xsl:function>

    <xsl:function name="pcm:get-bookmark-text" as="xs:string">
        <xsl:param name="element" as="element()?"/>
        <xsl:variable name="result">
            <xsl:choose>
                <xsl:when test="not($element) or $element/self::w:bookmarkEnd[not(preceding-sibling::w:bookmarkEnd)]">
                    <!-- Done; the predicate is because we want the leftmost bookmarkEnd if there are more, BTW: we cannnot rely on the ids, it seems. -->
                </xsl:when>
                <xsl:when test="$element/self::w:fldSimple">
                    <!-- w:fldSimple is an alternative way of making a bookmark. -->
                    <xsl:value-of select="concat($element/w:r/w:t, pcm:get-bookmark-text($element/following-sibling::*[1]))"/>
                </xsl:when>
                <xsl:when test="$element/self::w:r[w:t]">
                    <xsl:value-of select="concat($element/w:t, pcm:get-bookmark-text($element/following-sibling::*[1]))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="pcm:get-bookmark-text($element/following-sibling::*[1])"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$result"/>
    </xsl:function>

    <xsl:function name="pcm:pIsEmpty" as="xs:boolean">
        <xsl:param name="p" as="element(w:p)"/>
        <xsl:choose>
            <xsl:when test="exists($p//w:drawing)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:when test="exists($p//w:object)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="xs:boolean(normalize-space(string-join($p/w:r/w:t, '')) eq '')"/>
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
                        <xsl:value-of select="concat($style-prefix, 'background-color_', $shading)"/>
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
                <xsl:variable name="tblBorders" select="$styledoc/w:styles/w:style[@w:type = 'table' and @w:styleId = $tableStyleName]/w:tblPr/w:tblBorders" as="element(w:tblBorders)?"/>

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
        <xsl:param name="elementLocalName" as="xs:string"/>
        <!-- Disregard the namespace, to make it simple (we are in the correct context) -->

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

                <xsl:variable name="top" select="
                        if ($tcBorders/w:top and not($tcBorders/w:top/@w:val = 'none')) then
                            'CSS_border-top-style:solid '
                        else
                            ''"/>

                <xsl:variable name="left" select="
                        if ($tcBorders/w:left and not($tcBorders/w:left/@w:val = 'none')) then
                            'CSS_border-left-style:solid '
                        else
                            ''"/>

                <xsl:variable name="bottom"
                    select="
                        if ((pcm:tableDefinesBorder($currentCell, 'insideH') and not(pcm:atLastRow($currentCell))) or
                        ($tcBorders/w:bottom and not($tcBorders/w:bottom/@w:val = 'none'))) then
                            'CSS_border-bottom-style:solid '
                        else
                            ''"/>

                <xsl:variable name="right"
                    select="
                        if ((pcm:tableDefinesBorder($currentCell, 'insideV') and not(pcm:atRightmostColumn($currentCell))) or
                        ($tcBorders/w:right and not($tcBorders/w:right/@w:val = 'none'))) then
                            'CSS_border-right-style:solid '
                        else
                            ''"/>

                <xsl:variable name="aux1" select="normalize-space(concat($top, $left, $bottom, $right))"/>
                <xsl:variable name="aux2" select="
                        if ($aux1 != '') then
                            concat($aux1, ' ', 'CSS_border-collapse:collapse')
                        else
                            ''"/>

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
        <xsl:value-of select="
                count($currentCell/preceding-sibling::w:tc[not(w:tcPr/w:gridSpan)]) +
                sum($currentCell/preceding-sibling::w:tc/w:tcPr/w:gridSpan/@w:val) + 1"/>
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

    <xsl:function name="pcm:lookupParagraphStyleElement" as="element(w:style)">
        <xsl:param name="styleid" as="xs:string?"/>
        <xsl:variable name="elmt" select="$styledoc/w:styles/w:style[@w:type = 'paragraph' and @w:styleId = $styleid]" as="element(w:style)?"/>
        <xsl:sequence select="
                if ($elmt) then
                    $elmt
                else
                    $styledoc/w:styles/w:style[@w:type = 'paragraph' and @w:default = '1']"/>
    </xsl:function>

    <xsl:function name="pcm:lookupParagraphStyleName" as="xs:string">
        <xsl:param name="styleid"/>
        <xsl:value-of select="pcm:replaceFunnyCharacters(pcm:lookupParagraphStyleElement($styleid)/w:name/@w:val)"/>
    </xsl:function>

    <xsl:function name="pcm:getStyleForP" as="xs:string">
        <xsl:param name="element" as="element(w:p)"/>
        <xsl:value-of select="pcm:lookupParagraphStyleName($element/w:pPr/w:pStyle/@w:val)"/>
    </xsl:function>

    <xsl:function name="pcm:isListStyle" as="xs:boolean">
        <xsl:param name="element" as="element(w:p)"/>
        <xsl:variable name="style" select="pcm:getStyleForP($element)" as="xs:string"/>
        <xsl:sequence select="some $list-style-name in $list-style-names satisfies starts-with($style, $list-style-name)"/>
    </xsl:function>

    <xsl:function name="pcm:listlevel" as="xs:integer">
        <xsl:param name="element" as="element(w:p)"/>
        <!-- We base the level on the style name, instead of using the ilvl value from Word.
             First, this is very simple, second, the customer has much influence and third, we were getting
             tired of the various approaches of Word to specify levels and indentation.
        -->
        <xsl:variable name="style" select="pcm:getStyleForP($element)"/>
        <xsl:variable name="aux1" as="xs:string?">
            <xsl:choose>
                <xsl:when test="starts-with($style, 'list_number')">
                    <xsl:value-of select="substring-after($style, 'list_number')"/>
                </xsl:when>
                <xsl:when test="starts-with($style, 'list_bullet')">
                    <xsl:value-of select="substring-after($style, 'list_bullet')"/>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="aux2" select="
                if (starts-with($aux1, '_')) then
                    substring-after($aux1, '_')
                else
                    string($aux1)" as="xs:string"/>

        <xsl:sequence select="
                if ($aux2 = '') then
                    1
                else
                    xs:integer($aux2)"/>
    </xsl:function>

    <xsl:function name="pcm:isListParagraphStyle" as="xs:boolean">
        <xsl:param name="element" as="element(w:p)"/>
        <xsl:variable name="styleForP" select="pcm:getStyleForP($element)"/>
        <xsl:sequence select="$styleForP eq 'List_Paragraph' or starts-with($styleForP, 'List_Number')"/>
    </xsl:function>

    <xsl:function name="pcm:getExcelOLEObject" as="element(o:OLEObject)?">
        <xsl:param name="element" as="element(w:p)"/>
        <xsl:sequence select="$element/w:r/w:object/o:OLEObject[@Type = 'Link' and starts-with(@ProgID, 'Excel')]"/>
    </xsl:function>

    <xsl:function name="pcm:isExcelObject" as="xs:boolean">
        <xsl:param name="element" as="element(w:p)"/>
        <xsl:sequence select="exists(pcm:getExcelOLEObject($element))"/>
    </xsl:function>

    <xsl:function name="pcm:getExcelConref" as="xs:string">
        <xsl:param name="element" as="element(w:p)"/>
        <xsl:variable name="oleObject" select="pcm:getExcelOLEObject($element)" as="element(o:OLEObject)"/>
        <xsl:value-of select="concat($documentrelsdoc/rels:Relationships/rels:Relationship[@Id eq $oleObject/@r:id]/@Target, '#tabletopic/table')"/>
    </xsl:function>

    <xsl:function name="pcm:getHyperlinkTarget" as="xs:string">
        <xsl:param name="hyperlink" as="element(w:hyperlink)"/>
        <xsl:value-of select="$documentrelsdoc/rels:Relationships/rels:Relationship[@Id eq $hyperlink/@r:id]/@Target"/>
    </xsl:function>

    <xsl:function name="pcm:get-language-attribute" as="attribute(xml:lang)?">
        <xsl:param name="node" as="node()"/>
        <xsl:choose>
            <xsl:when test="$language-code ne ''">
                <xsl:attribute name="xml:lang" select="$language-code"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="lang" select="
                        if ($language-code ne '') then
                            $language-code
                        else
                            ($node//w:lang/@w:val)[1]" as="xs:string?"/>
                <xsl:choose>
                    <xsl:when test="$lang">
                        <xsl:attribute name="xml:lang" select="substring-before($lang, '-')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template match="rels:Relationships">
        <!-- Start the main convertion: -->
        <xsl:apply-templates select="$worddoc"/>
    </xsl:template>

    <xsl:template match="w:document">
        <article>
            <xsl:copy-of select="pcm:get-language-attribute(.)"/>
            <front>
                <journal-meta>
                    <journal-id/>
                    <issn/>
                </journal-meta>
                <article-meta>
                    <title-group>
                        <article-title/>
                    </title-group>
                    <pub-date>
                        <year/>
                    </pub-date>
                </article-meta>
            </front>
            <xsl:apply-templates select="w:body"/>
        </article>
    </xsl:template>

    <xsl:template match="w:body">
        <xsl:variable name="stage1">
            <body>
                <xsl:apply-templates/>
            </body>
        </xsl:variable>

        <!--<xsl:message>Denk aan /tmp/klad.xml!</xsl:message>
        <xsl:result-document href="/tmp/klad.xml"><xsl:copy-of select="$stage1"/></xsl:result-document>-->

        <xsl:apply-templates select="$stage1" mode="stage2"/>
    </xsl:template>

    <xsl:function name="pcm:normalize-bookmark-id"  as="xs:string">
        <xsl:param name="bookmarkname" as="xs:string"/>
        <xsl:value-of select="translate($bookmarkname, ':', '_')"/>
    </xsl:function>

    <!--<xsl:template match="w:bookmarkStart[not(following-sibling::w:bookmarkStart)]">
        <!-\- The predicate not(following-sibling::bookmarkStart)] is because sometimes there are two bookmarkStart elements (and judging by the ids, the corresponding
             bookmarkEnds do not give a proper nesting). -\->
        <styled-content id="{pcm:normalize-bookmark-id(@w:name)}" style="{concat($style-bookmark, ' ', $style-prefix, 'id-', pcm:get-xref-type(.))}">
            <xsl:value-of select="pcm:get-bookmark-text(.)"/>
        </styled-content>
    </xsl:template>-->
    <xsl:template match="w:bookmarkStart">
        <styled-content id="{pcm:normalize-bookmark-id(@w:name)}" style="{concat($style-bookmark, ' ', $style-prefix, 'id-', pcm:get-xref-type(.))}">
            <xsl:value-of select="pcm:get-bookmark-text(.)"/>
        </styled-content>
    </xsl:template>

    <xsl:template match="w:fldSimple[not(pcm:bookmarkstart-precedes(.))]">
        <xsl:variable name="fieldcode" select="@w:instr"/>
        <xsl:variable name="seqtype" select="lower-case(replace($fieldcode, '^ *SEQ +([^ ]+).*$', '$1'))" as="xs:string?"/>
        <styled-content style="{concat($style-bookmark, ' ', $style-prefix, 'id-', $seqtype, ' ', $style-prefix, 'nobookmark')}">
            <xsl:value-of select="w:r/w:t"/>
        </styled-content>
    </xsl:template>

    <xsl:template match="w:p">
        <xsl:variable name="style" select="pcm:getStyleForP(.)"/>

        <xsl:choose>
            <xsl:when test="parent::w:body and matches($style, 'heading_[1-9]')">
                <!-- Make it a section title with a style: -->
                <p>
                    <xsl:apply-templates select="w:r | w:bookmarkStart | w:fldSimple"/>
                    <!-- Plaats de processing-instruction aan het eind van de <p> om te voorkomen dat we problemen krijgen als templates een attribuut aan deze <p> willen toevoegen. -->
                    <xsl:processing-instruction name="style" select="concat($style-prefix, 'heading_', substring-after($style, '_'))"/>
                </p>
            </xsl:when>
            <xsl:when test="pcm:isListStyle(.)">
                <!-- Convert list-styles to real list items (the list container will be generated later, together with the real <li>'s) -->
                <xsl:variable name="level" select="pcm:listlevel(.)" as="xs:integer"/>

                <xsl:variable name="numPr" select="
                        if (w:pPr/w:numPr)
                        then
                            w:pPr/w:numPr
                        else
                            pcm:lookupParagraphStyleElement(w:pPr/w:pStyle/@w:val)/w:pPr/w:numPr"
                    as="element(w:numPr)?"/>
                <xsl:variable name="ilvl" select="
                        if ($numPr/w:ilvl) then
                            xs:integer($numPr/w:ilvl/@w:val)
                        else
                            0" as="xs:integer"/>
                <xsl:variable name="numIdElement" select="$numPr/w:numId" as="element(w:numId)?"/>
                <LI level="{$level}" style="{$style}" listtype="{if ($numIdElement) then pcm:lookupListStyleType($numIdElement/@w:val, $ilvl) else ''}">
                    <p>
                        <xsl:apply-templates select="w:r | w:bookmarkStart | w:fldSimple"/>
                    </p>
                </LI>
            </xsl:when>
            <xsl:when test="pcm:isExcelObject(.)">
                <table-wrap>
                    <table style="{concat($style-prefix, 'excel')}" conref="{pcm:getExcelConref(.)}">
                        <!-- Even though we use a conref, it is required that the table has all required child elements. -->
                        <tgroup cols="1">
                            <tbody>
                                <row>
                                    <entry/>
                                </row>
                            </tbody>
                        </tgroup>
                    </table>
                </table-wrap>
            </xsl:when>
            <!-- Suppress empty p's: -->
            <xsl:when test="pcm:pIsEmpty(.)"/>
            <xsl:otherwise>
                <!-- Styles that we don't know are considered standard (Standaard), but we store the original name as well. -->
                <p>
                    <xsl:apply-templates select="w:r | w:bookmarkStart | w:fldSimple | w:hyperlink"/>
                    <!-- Plaats de processing-instruction aan het eind van de <p> om te voorkomen dat we problemen krijgen als templates een attribuut aan deze <p> willen toevoegen. -->
                    <xsl:processing-instruction name="style" select="normalize-space(concat($style-prefix, 'standard ', $style-prefix, $style))"/>
                </p>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="match-text">
        <xsl:apply-templates select="w:t | w:footnoteReference | w:footnoteRef | w:drawing | w:br"/>
        <xsl:if test="not(pcm:bookmarkstart-precedes(.))">
            <xsl:variable name="begin-field" select="following-sibling::*[1]/self::w:r[pcm:has-field-start(.)]" as="element()?"/>
            <xsl:if test="$begin-field">
                <xsl:sequence select="pcm:build-field($begin-field)"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <xsl:function name="pcm:has-field-start" as="xs:boolean">
        <xsl:param name="r" as="element(w:r)"/>
        <xsl:sequence select="exists($r/w:fldChar[@w:fldCharType = 'begin'])"/>
    </xsl:function>

    <xsl:template match="w:hyperlink[@r:id]">
        <ext-link xlink:href="{pcm:getHyperlinkTarget(.)}">
            <xsl:apply-templates/>
        </ext-link>
    </xsl:template>

    <xsl:template match="w:hyperlink[@w:anchor]">
        <xref rid="{pcm:normalize-bookmark-id(@w:anchor)}">
            <xsl:apply-templates/>
        </xref>
    </xsl:template>
    
    <xsl:template match="w:r[not(w:rPr) or w:rPr[not(*)]]">
        <xsl:choose>
            <xsl:when test="not(preceding-sibling::w:r) and pcm:has-field-start(.)">
                <!-- Special treatment for fields at the start of a paragraph -->
                <xsl:sequence select="pcm:build-field(.)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="match-text"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="w:r[w:rPr/*]">
        <xsl:variable name="styled-content">
            <styled-content>
                <!-- Translate style attributes from w:rPr to and style attribute with the converted values: -->
                <xsl:apply-templates select="w:rPr"/>
                <!-- Place the text inside the styled-content: -->
                <xsl:call-template name="match-text"/>
            </styled-content>
        </xsl:variable>

        <xsl:if test="$styled-content != '' or ($styled-content//graphic)">
            <xsl:apply-templates select="$styled-content" mode="replace-styled-content"/>
        </xsl:if>
    </xsl:template>
    
    <!-- Onderdruk w:sdtPr en w:sdtEndPr zolang we niet weten wat het is, omdat de geneste w:rPr problemen veroorzaakt. -->
    <xsl:template match="w:sdtPr | w:sdtEndPr"/>        
       
    <xsl:template match="w:rPr">
        <xsl:variable name="fontsize" select="
            
                if (w:sz) then
                    concat($style-prefix, 'font-size_', w:sz/@w:val div 2, ' ')
                else
                    ''"/>
        <xsl:variable name="boldstyle" select="
                if (w:b) then
                    concat($style-prefix, 'font-weight_bold ')
                else
                    ''"/>
        <xsl:variable name="italicstyle" select="
                if (w:i) then
                    concat($style-prefix, 'font-style_italic ')
                else
                    ''"/>
        <xsl:variable name="underlinestyle" select="
                if (w:u) then
                    concat($style-prefix, 'text-decoration_underline ')
                else
                    ''"/>
        <xsl:variable name="superscriptstyle" select="
                if (w:vertAlign/@w:val = 'superscript') then
                    concat($style-prefix, 'vertical-align_super ')
                else
                    ''"/>
        <xsl:variable name="subscriptstyle" select="
                if (w:vertAlign/@w:val = 'subscript') then
                    concat($style-prefix, 'vertical-align_sub ')
                else
                    ''"/>
        <xsl:variable name="colorstyle" select="
                if (w:color) then
                    concat($style-prefix, 'color_', w:color/@w:val, ' ')
                else
                    ''"/>
        <xsl:variable name="highlight" select="
                if (w:highlight) then
                    concat($style-prefix, 'background-color_', w:highlight/@w:val, ' ')
                else
                    ''"/>
        <xsl:variable name="shd" select="
                if (w:shd) then
                    concat($style-prefix, 'background-color_', w:shd/@w:fill, ' ')
                else
                    ''"/>
        <xsl:variable name="strike" select="
                if (w:strike) then
                    concat($style-prefix, 'text-decoration_line-through ')
                else
                    ''"/>

        <xsl:variable name="style" select="
                normalize-space(concat($fontsize, $boldstyle, $italicstyle, $underlinestyle, $superscriptstyle,
                $subscriptstyle, $colorstyle, $highlight, $shd, $strike))"/>

        <xsl:variable name="aux1" select="w:rStyle/@w:val"/>
        <xsl:variable name="aux2" select="
                if ($aux1 != '') then
                    concat($style-prefix, pcm:lookupCharactereStyleName($aux1))
                else
                    ''"/>
        <xsl:variable name="style" select="normalize-space(concat($aux2, ' ', $style))"/>

        <xsl:if test="$style != ''">
            <!-- Note: many of the style names in @style will later be replaced by Dita elements like <b>, <i> and <sup> -->
            <xsl:attribute name="style" select="$style"/>
        </xsl:if>
    </xsl:template>

    <xsl:function name="pcm:field-end-ahead" as="xs:boolean">
        <xsl:param name="r" as="element()?"/>
        <xsl:choose>
            <xsl:when test="not($r)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:when test="$r/w:fldChar[@w:fldCharType = 'begin']">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:when test="$r/w:fldChar[@w:fldCharType = 'end']">
                <xsl:sequence select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="pcm:field-end-ahead($r/following-sibling::*[1])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="pcm:bookmarkstart-precedes">
        <xsl:param name="elmt" as="element()?"/>
        <xsl:choose>
            <xsl:when test="not($elmt)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:when test="$elmt/self::w:bookmarkEnd">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:when test="$elmt/self::w:bookmarkStart">
                <xsl:sequence select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="pcm:bookmarkstart-precedes($elmt/preceding-sibling::*[1])"/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>

    <xsl:template match="w:t">
        <xsl:choose>
            <xsl:when test="pcm:bookmarkstart-precedes(parent::*) or pcm:bookmarkstart-precedes(parent::*/parent::w:fldSimple)">
                <xsl:comment>Field text removed because of bookmarkStart: <xsl:value-of select="."/></xsl:comment>
            </xsl:when>
            <xsl:when test="pcm:field-end-ahead(parent::*)">
                <xsl:comment>Field text removed because of field end: <xsl:value-of select="."/></xsl:comment>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="styled-content[not(@*)]" mode="replace-styled-content">
        <!-- Leave out the  element -->
        <xsl:apply-templates mode="replace-styled-content"/>
    </xsl:template>

    <xsl:template match="style-content[@style]" mode="replace-styled-content">
        <!-- Remove all known Word styles (represented as styles with style names) from the @style attribute and store them in the $new-output-class variable: -->
        <xsl:variable name="new-output-class" select="
                normalize-space(
                replace(@style, concat($style-prefix, '(font-weight_bold|font-style_italic|text-decoration_underline|vertical-align_super|vertical-align_sub)'), ''))"/>
        <!-- Additionally, remove all styles used by DAF; they will also be dealt with later (in the template named "replace-") and converted to  elements
             (make sure to deal with these styles in template <xsl:template name="replace-">):
        -->
        <xsl:variable name="new-output-class" select="replace($new-output-class, concat($style-prefix, '(Emphasis|Subscript|Superscript|Formula|Strong)'), '')"/>

        <xsl:choose>
            <xsl:when test="$new-output-class != ''">
                <!-- There were other style names then the known ones. Create a <styled-content> for them with the style attribute set to the new-output-class variable: -->
                <styled-content style="{$new-output-class}">
                    <!-- Deal with both the known and unknown output classes, i.e., create a  element for each of them: -->
                    <xsl:call-template name="replace-">
                        <xsl:with-param name="style" select="@style"/>
                    </xsl:call-template>
                </styled-content>
            </xsl:when>
            <xsl:otherwise>
                <!-- There were only known output classes. No need to create a  element; they will be created by dealing with the known output classes: -->
                <xsl:call-template name="replace-">
                    <xsl:with-param name="style" select="@style"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="@* | node()" mode="replace-styled-content">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="replace-styled-content"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template name="replace-">
        <xsl:param name="style" required="yes"/>
        <xsl:choose>
            <xsl:when test="contains($style, concat($style-prefix, 'font-weight_bold'))">
                <b>
                    <xsl:call-template name="replace-">
                        <xsl:with-param name="style" select="replace($style, concat($style-prefix, 'font-weight_bold'), '')"/>
                    </xsl:call-template>
                </b>
            </xsl:when>
            <xsl:when test="contains($style, concat($style-prefix, 'font-style_italic'))">
                <i>
                    <xsl:call-template name="replace-">
                        <xsl:with-param name="style" select="replace($style, concat($style-prefix, 'font-style_italic'), '')"/>
                    </xsl:call-template>
                </i>
            </xsl:when>
            <xsl:when test="contains($style, concat($style-prefix, 'text-decoration_underline'))">
                <u>
                    <xsl:call-template name="replace-">
                        <xsl:with-param name="style" select="replace($style, concat($style-prefix, 'text-decoration_underline'), '')"/>
                    </xsl:call-template>
                </u>
            </xsl:when>
            <xsl:when test="contains($style, concat($style-prefix, 'vertical-align_super'))">
                <sup>
                    <xsl:call-template name="replace-">
                        <xsl:with-param name="style" select="replace($style, concat($style-prefix, 'vertical-align_super'), '')"/>
                    </xsl:call-template>
                </sup>
            </xsl:when>
            <xsl:when test="contains($style, concat($style-prefix, 'vertical-align_sub'))">
                <sub>
                    <xsl:call-template name="replace-">
                        <xsl:with-param name="style" select="replace($style, concat($style-prefix, 'vertical-align_sub'), '')"/>
                    </xsl:call-template>
                </sub>
            </xsl:when>
            <!-- DAF style names translated here; make sure to include the names in the regular expression in the
                template <xsl:template match="[@style]" mode="replace-">: -->
            <xsl:when test="contains($style, 'Emphasis')">
                <i>
                    <xsl:call-template name="replace-">
                        <xsl:with-param name="style" select="replace($style, concat($style-prefix, 'Emphasis'), '')"/>
                    </xsl:call-template>
                </i>
            </xsl:when>
            <xsl:when test="contains($style, 'Strong')">
                <b>
                    <xsl:call-template name="replace-">
                        <xsl:with-param name="style" select="replace($style, concat($style-prefix, 'Strong'), '')"/>
                    </xsl:call-template>
                </b>
            </xsl:when>
            <xsl:when test="contains($style, 'Subscript')">
                <sub>
                    <xsl:call-template name="replace-">
                        <xsl:with-param name="style" select="replace($style, concat($style-prefix, 'Subscript'), '')"/>
                    </xsl:call-template>
                </sub>
            </xsl:when>
            <xsl:when test="contains($style, 'Superscript')">
                <sup>
                    <xsl:call-template name="replace-">
                        <xsl:with-param name="style" select="replace($style, concat($style-prefix, 'Superscript'), '')"/>
                    </xsl:call-template>
                </sup>
            </xsl:when>
            <xsl:when test="contains($style, 'Formula')">
                <codeph>
                    <xsl:call-template name="replace-">
                        <xsl:with-param name="style" select="replace($style, concat($style-prefix, 'Formula'), '')"/>
                    </xsl:call-template>
                </codeph>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="@* | node()" mode="replace-styled-content"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="w:br">
        <!-- TODO Dita has no br. Do something fuzzy with p elements? -->
        <xsl:choose>
            <xsl:when test="@w:type eq 'page'">
                <xsl:processing-instruction name="pagebreak"/>
            </xsl:when>
            <xsl:otherwise>
                <styled-content style="{concat($style-prefix, 'br')}"/>

            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="w:drawing">
        <xsl:variable name="imageFileName" select="pcm:determine-image-file-name(.//pic:pic[1]/pic:blipFill[1]/a:blip)"/>

        <xsl:variable name="mimetype" as="xs:string" select="pcm:extension-from-filename($imageFileName)"/>
        <fig>
            <graphic xlink:href="{$imageFileName}">
                <xsl:if test="$mimetype"><xsl:attribute name="mimetype" select="$mimetype"/></xsl:if>
            </graphic>
        </fig>
    </xsl:template>

    <xsl:template match="w:footnoteReference">
        <!-- w:footnoteReference is in the main document. -->
        <styled-content style="{concat($style-prefix, 'footnoteNum')}">
            <!-- TODO Check the format of anchors -->
            <xref id="{concat($FOOTNOTEBACKPREFIX, generate-id())}" href="{concat('#', $FOOTNOTEPREFIX, generate-id())}">
                <xsl:number/>
            </xref>
        </styled-content>
    </xsl:template>

    <xsl:template match="w:footnoteReference" mode="footnotepull">
        <xsl:variable name="id" select="generate-id()" as="xs:string"/>
        <sectiondiv style="{concat($style-prefix, 'footnote')}">
            <xsl:variable name="fnid" select="@w:id" as="xs:string"/>
            <xsl:apply-templates select="$footnotedoc/w:footnotes/w:footnote[@w:id = $fnid]/*">
                <xsl:with-param name="id" select="$id" tunnel="yes" as="xs:string"/>
            </xsl:apply-templates>
        </sectiondiv>
    </xsl:template>

    <xsl:template match="w:footnoteRef">
        <!-- w:footnoteRef is in the footnotes document. -->
        <xsl:param name="id" required="yes" tunnel="yes"/>
        <styled-content style="{concat($style-prefix, 'footnoteNum')}">
            <xref href="{concat('#', $FOOTNOTEBACKPREFIX, $id)}" id="{concat($FOOTNOTEPREFIX, $id)}">
                <xsl:number/>
            </xref>
        </styled-content>
    </xsl:template>

    <xsl:template match="w:tbl">
        <table-wrap>
            <table>
                <colgroup>
                    <!-- Generate a style attribute for any borders. Note that this currently excludes any other style properties. -->
                    <xsl:call-template name="doTableBorders"/>
                    
                    <xsl:choose>
                        <xsl:when test="$absolute-table-column-width eq 'yes'">
                            <xsl:for-each select="w:tblGrid/w:gridCol">
                                <xsl:variable name="width" select="xs:integer(@w:w)"/>
                                <col width="{concat($width div $word-to-inch-divisor-for-tables, 'in')}"/>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:variable name="colwidths" as="xs:integer+" select="for $col in w:tblGrid/w:gridCol return xs:integer($col/@w:w)"/>
                            <xsl:variable name="summed-colwidths" as="xs:integer" select="sum($colwidths)"/>
                            <xsl:for-each select="w:tblGrid/w:gridCol">
                                <xsl:variable name="width" as="xs:integer" select="xs:integer(@w:w)"/>
                                <xsl:variable name="percentage" as="xs:float" select="100 div ($summed-colwidths div $width)"/>
                                <col width="{format-number($percentage, '#.##') || '%'}"/>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>
                </colgroup>
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
                            <tr>
                                <td><p><xsl:value-of select="pcm:errormessage('No data found')"/></p></td>
                            </tr>
                        </xsl:otherwise>
                    </xsl:choose>
                </tbody>
            </table>
        </table-wrap>
    </xsl:template>

    <xsl:template name="doTableBorders">
        <xsl:if test="$apply-table-borders = 'yes'">
            <xsl:variable name="top" select="
                    if (pcm:tableDefinesBorder(., 'top')) then
                        'CSS_border-top-style:solid '
                    else
                        ''"/>
            <xsl:variable name="left" select="
                    if (pcm:tableDefinesBorder(., 'left')) then
                        'CSS_border-left-style:solid '
                    else
                        ''"/>
            <xsl:variable name="bottom" select="
                    if (pcm:tableDefinesBorder(., 'bottom')) then
                        'CSS_border-bottom-style:solid '
                    else
                        ''"/>
            <xsl:variable name="right" select="
                    if (pcm:tableDefinesBorder(., 'right')) then
                        'CSS_border-right-style:solid '
                    else
                        ''"/>

            <xsl:variable name="aux" select="normalize-space(concat($top, $left, $bottom, $right))"/>
            <xsl:variable name="style" select="
                    if ($aux != '') then
                        concat($aux, ' CSS_border-collapse:collapse')
                    else
                        ''"/>

            <xsl:if test="$style != ''">
                <xsl:attribute name="style" select="$style"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <xsl:template match="w:tr">
        <tr>
            <!-- Leaving out formatting properties of the row -->
            <xsl:apply-templates select="w:tc"/>
        </tr>
    </xsl:template>

    <xsl:template match="w:tc">
        <!-- Een verticale span begint bij w:tcPr/w:vMerge met @w:val="restart". De onderliggende cellen zijn leeg,
             en worden gekenmerkt door w:tcPr/w:vMerge zonder @w:val-attribuut. -->
        <xsl:if test="not(w:tcPr/w:vMerge) or w:tcPr/w:vMerge[@w:val = 'restart']">
            <td>
                <!-- Leaving out most formatting properties of the cell -->

                <!-- Generate style attribute if shading or borders supplied. Note that this currently excludes any other style properties. -->
                <xsl:variable name="shading" as="xs:string" select="pcm:cellShading(.)"/>
                <xsl:variable name="borders" as="xs:string" select="pcm:cellBorders(.)"/>

                <xsl:variable name="style" select="normalize-space(concat($shading, $borders))"/>
                <xsl:if test="$style != ''">
                    <xsl:attribute name="style" select="$style"/>
                </xsl:if>

                <xsl:if test="w:tcPr/w:gridSpan/@w:val != ''">
                    <!--<xsl:variable name="colnum" select="pcm:get-colnum(.)"/>
                    <xsl:attribute name="namest" select="concat('c', $colnum)"/>
                    <xsl:attribute name="nameend" select="concat('c', $colnum + (w:tcPr/w:gridSpan/@w:val - 1))"/>-->
                    <xsl:attribute name="colspan" select="w:tcPr/w:gridSpan/@w:val"/>
                </xsl:if>

                <xsl:if test="w:tcPr/w:vMerge/@w:val = 'restart'">
                    <xsl:variable name="colnum" select="position()"/>
                    <!--<xsl:attribute name="morerows" select="pcm:count-span-rows(., $colnum) - 1"/>-->
                    <xsl:attribute name="rowspan" select="pcm:count-span-rows(., $colnum)"/>
                </xsl:if>

                <xsl:apply-templates select="*[not(self::w:tcPr)]"/>
            </td>
        </xsl:if>
    </xsl:template>

    <!-- Stage 2 templates: -->

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

    <xsl:function name="pcm:get-list-type" as="xs:string">
        <xsl:param name="style" as="xs:string?"/>
        <xsl:param name="level" as="xs:integer?"/>
        <xsl:choose>
            <xsl:when test="$style = ('list_unordered', 'bullet')">
                <xsl:value-of select="'bullet'"/>
            </xsl:when>
            <xsl:when test="$style = ('list_arabic', 'list_arabic_continued', 'decimal')">
                <xsl:value-of select="'order'"/>
            </xsl:when>
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
            <xsl:processing-instruction name="style" select="$listItem/@style"/>
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
