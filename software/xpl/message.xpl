<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step type="pcm:debug-message" xmlns:p="http://www.w3.org/ns/xproc"
    xmlns:pcm="http://www.masereeuw.nl/xslt/3.0/functions"
    xmlns:c="http://www.w3.org/ns/xproc-step"
    xmlns:cx="http://xmlcalabash.com/ns/extensions" version="1.0">
    
    <p:documentation>Writes a message to stdout.</p:documentation>
    
    <p:input port="source" primary="true" sequence="true"/>
    <p:output port="result" primary="true" sequence="true"/>

    <p:option name="message" required="true"/>
    <p:option name="debug" required="true"/>

    <p:choose>
        <p:when test="$debug eq 'true'">
            <cx:message><p:with-option name="message" select="$message"/></cx:message>
        </p:when>
        <p:otherwise><p:identity/></p:otherwise>
    </p:choose>
</p:declare-step>
