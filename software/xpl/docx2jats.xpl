<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step
    xmlns:p="http://www.w3.org/ns/xproc"
    xmlns:pcm="http://www.masereeuw.nl/xslt/3.0/functions"
    xmlns:c="http://www.w3.org/ns/xproc-step"
    xmlns:cx="http://xmlcalabash.com/ns/extensions"
    version="1.0">

    <p:option name="debug" required="false" select="string(false())"/>
    <p:option name="relsfile" required="true"/>
    <p:option name="outputfile" required="true"/>
    <p:option name="language-code" required="false"/>
    <p:option name="style-prefix" select="'IB-'"/>
    <p:option name="prefix-to-rng-schema" select="''"/>
    <p:option name="prefix-to-sch-schema" select="''"/>

    <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
    
    <p:import href="message.xpl"/>
    <p:import href="tee.xpl"/>
    
    <p:load name="load">
        <p:with-option name="href" select="$relsfile"/>
    </p:load>
    
    <p:xslt name="stap1">
        <p:input port="stylesheet">
            <p:document href="../xslt/docx2jats.xslt"/>
        </p:input>
        <p:with-param name="debug" select="$debug"/>
        <p:with-param name="language-code" select="$language-code"/>
        <p:with-param name="style-prefix" select="$style-prefix"/>
    </p:xslt>
    
    <p:choose>
        <p:when test="$debug eq 'true'">
            <pcm:tee>
                <p:with-option name="href" select="'/tmp/DEBUG/010.xml'"/>
                <p:with-option name="indent" select="true()"/>
            </pcm:tee>
        </p:when>
        <p:otherwise>
            <p:identity/>
        </p:otherwise>
    </p:choose>
    
    <p:xslt name="stap2">
        <p:input port="stylesheet">
            <p:document href="../xslt/apply-jats-sections.xslt"/>
        </p:input>
        <p:with-param name="debug" select="$debug"/>
        <p:with-param name="style-prefix" select="$style-prefix"/>
    </p:xslt>
    
    <p:choose>
        <p:when test="$debug eq 'true'">
            <pcm:tee>
                <p:with-option name="href" select="'/tmp/DEBUG/020.xml'"/>
                <p:with-option name="indent" select="true()"/>
            </pcm:tee>
        </p:when>
        <p:otherwise>
            <p:identity/>
        </p:otherwise>
    </p:choose>
    
    <p:xslt name="stap3">
        <p:input port="stylesheet">
            <p:document href="../xslt/apply-ibo-ids.xslt"/>
        </p:input>
        <p:with-param name="debug" select="$debug"/>
    </p:xslt>
    
    <p:choose>
        <p:when test="$debug eq 'true'">
            <pcm:tee>
                <p:with-option name="href" select="'/tmp/DEBUG/030.xml'"/>
                <p:with-option name="indent" select="true()"/>
            </pcm:tee>
        </p:when>
        <p:otherwise>
            <p:identity/>
        </p:otherwise>
    </p:choose>
    
    <p:xslt name="stap4">
        <p:input port="stylesheet">
            <p:document href="../xslt/deal-with-anchors.xslt"/>
        </p:input>
        <p:with-param name="debug" select="$debug"/>
    </p:xslt>

    <p:choose>
        <p:when test="$debug eq 'true'">
            <pcm:tee>
                <p:with-option name="href" select="'/tmp/DEBUG/040.xml'"/>
                <p:with-option name="indent" select="true()"/>
            </pcm:tee>
        </p:when>
        <p:otherwise>
            <p:identity/>
        </p:otherwise>
    </p:choose>
    
    <p:xslt name="stap5">
        <p:input port="stylesheet">
            <p:document href="../xslt/deal-with-front.xslt"/>
        </p:input>
        <p:with-param name="debug" select="$debug"/>
    </p:xslt>
    
    <p:choose>
        <p:when test="$debug eq 'true'">
            <pcm:tee>
                <p:with-option name="href" select="'/tmp/DEBUG/050.xml'"/>
                <p:with-option name="indent" select="true()"/>
            </pcm:tee>
        </p:when>
        <p:otherwise>
            <p:identity/>
        </p:otherwise>
    </p:choose>
    
    <p:xslt name="stap6a">
        <p:input port="stylesheet">
            <p:document href="../xslt/remove-empty-styled-content.xslt"/>
        </p:input>
        <p:with-param name="debug" select="$debug"/>
    </p:xslt>
    
    <p:xslt name="stap6b">
        <p:input port="stylesheet">
            <p:document href="../xslt/fix-inlines.xslt"/>
        </p:input>
        <p:with-param name="debug" select="$debug"/>
    </p:xslt>
    
    <p:delete match="styled-content[not(node()) and not(@id)]"/>
    
    <p:choose>
        <p:when test="$debug eq 'true'">
            <p:identity/>
        </p:when>
        <p:otherwise>
            <p:delete match="processing-instruction()|comment()"/>
        </p:otherwise>
    </p:choose>
    
    <p:xslt name="stap7">
        <p:input port="stylesheet">
            <p:document href="../xslt/add-schemata.xslt"/>
        </p:input>
        <p:with-param name="debug" select="$debug"/>
        <p:with-param name="prefix-to-rng-schema" select="$prefix-to-rng-schema"/>
        <p:with-param name="prefix-to-sch-schema" select="$prefix-to-sch-schema"/>
    </p:xslt>
    
    <!-- TODO DOCTYPE-SYSTEM-->
    <p:store name="store-file" indent="false" omit-xml-declaration="false">
        <p:with-option name="href" select="$outputfile"/>
    </p:store>
</p:declare-step>
