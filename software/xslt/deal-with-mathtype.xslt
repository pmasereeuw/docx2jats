<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:mml="http://www.w3.org/1998/Math/MathML"
    xmlns:pcm="http://www.masereeuw.nl/xslt/3.0/functions"
    expand-text="yes"
    version="3.0">
    
    <xsl:function name="pcm:is-relevant"  as="xs:boolean">
        <xsl:param name="n" as="node()"/>
        <xsl:sequence select="exists($n[self::text() or self::element()])"/>
    </xsl:function>
    
    <xsl:function name="pcm:preceding-neighbour" as="node()?">
        <xsl:param name="n" as="node()"/>
        <xsl:sequence select="$n/preceding-sibling::node()[pcm:is-relevant(.)][1]"/>
    </xsl:function>
    
    <xsl:function name="pcm:following-neighbour" as="node()?">
        <xsl:param name="n" as="node()"/>
        <xsl:sequence select="$n/following-sibling::node()[pcm:is-relevant(.)][1]"/>
    </xsl:function>
    
    <xsl:function name="pcm:is-mathtype-styled-content"  as="xs:boolean">
        <xsl:param name="e" as="node()?"/>
        <xsl:sequence select="if ($e/self::styled-content) then 'IB-mtconvertedequation' = tokenize($e/@style, '\s+') else false()"/>
    </xsl:function>
    
    <xsl:function name="pcm:directly-preceding-mathtype"  as="element(styled-content)?">
        <xsl:param name="e" as="element(styled-content)"/>
        <xsl:variable name="neighbour" as="node()?" select="pcm:preceding-neighbour($e)"/>
        <xsl:choose>
            <xsl:when test="exists($neighbour[self::styled-content[pcm:is-mathtype-styled-content(.)]])">
                <xsl:sequence select="$neighbour"/>
            </xsl:when>
            <xsl:when test="empty($neighbour) and pcm:preceding-neighbour($e/parent::p)[self::p]/node()[pcm:is-relevant(.)][last()][pcm:is-mathtype-styled-content(.)]">
                <xsl:sequence select="($e/parent::p/preceding-sibling::p[1]/styled-content)[last()]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="pcm:directly-following-mathtype"  as="element(styled-content)?">
        <xsl:param name="e" as="element(styled-content)"/>
        <xsl:variable name="neighbour" as="node()?" select="pcm:following-neighbour($e)"/>
        <xsl:choose>
            <xsl:when test="exists($neighbour[self::styled-content[pcm:is-mathtype-styled-content(.)]])">
                <xsl:sequence select="$neighbour"/>
            </xsl:when>
            <xsl:when test="empty($neighbour) and pcm:following-neighbour($e/parent::p)[self::p]/node()[pcm:is-relevant(.)][1][pcm:is-mathtype-styled-content(.)]">
                <xsl:sequence select="($e/parent::p/following-sibling::p[1]/styled-content)[1]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="pcm:mathtype-precedes-directly"  as="xs:boolean">
        <xsl:param name="e" as="element(styled-content)"/>
        <xsl:sequence select="exists(pcm:directly-preceding-mathtype($e))"/>
    </xsl:function>
    
    <xsl:function name="pcm:process-mathtype"  as="text()*">
        <xsl:param name="e" as="element(styled-content)?"/>
        <xsl:choose>
            
            <xsl:when test="pcm:is-mathtype-styled-content($e)">
                <xsl:sequence select="($e/text(), pcm:process-mathtype(pcm:directly-following-mathtype($e)))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template match="styled-content[pcm:is-mathtype-styled-content(.)]">
        <xsl:choose>
            <xsl:when test="pcm:mathtype-precedes-directly(.)">
                <!-- suppress -->
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="math" as="xs:string" select="string-join(pcm:process-mathtype(.), '')"/>
                <!--<xsl:comment><xsl:value-of select="$math"/></xsl:comment>-->
                <xsl:try>                    
                    <xsl:apply-templates select="parse-xml('&lt;MATHDUMMY>' || $math || '&lt;/MATHDUMMY>')" mode="mathml"/>
                    <xsl:catch>
                        <xsl:message>Error parsing MathML formula, formula is: "{$math}".</xsl:message>
                        <xsl:comment>Error parsing the following MathML formula</xsl:comment>
                        <xsl:value-of select="$math"/>
                    </xsl:catch>
                </xsl:try>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Leave out the empty p element that result after dealing with the math they contained. -->
    <xsl:template match="p[every $n in node() satisfies if (pcm:is-relevant($n)) then pcm:is-mathtype-styled-content($n) else true()]"/>
    
    <xsl:template match="MATHDUMMY" mode="mathml">
        <!-- Leave out the auxiliary wrapper. -->
        <xsl:apply-templates mode="mathml"/>
    </xsl:template>
    
    <xsl:template match="MATHDUMMY/*" mode="mathml">
        <!-- Leave out the auxiliary wrapper. -->
        <inline-formula>
            <xsl:element name="{'mml:' || local-name()}">
                <xsl:apply-templates select="@* | node()" mode="mathml"/>
            </xsl:element>
        </inline-formula>
    </xsl:template>
    
    <xsl:template match="*" mode="mathml">
        <xsl:element name="{'mml:' || local-name()}">
            <xsl:apply-templates select="@* | node()" mode="mathml"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="node() | @*" mode="#all" priority="-1">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
