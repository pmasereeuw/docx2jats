<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step type="pcm:tee" xmlns:p="http://www.w3.org/ns/xproc"
    xmlns:pcm="http://www.masereeuw.nl/xslt/3.0/functions"
    xmlns:c="http://www.w3.org/ns/xproc-step"
    xmlns:cx="http://xmlcalabash.com/ns/extensions" version="1.0">
    
    <p:documentation>Writes the current input to the file specified in href and passes the input unchanged to output, like the famous Unix command.</p:documentation>

    <p:input port="source" primary="true" sequence="false"/>
    <p:output port="result" primary="true" sequence="false"/>

    <p:option name="href" required="true"/>
    <p:option name="indent" required="false" select="string(true())"/>

    <p:identity name="original-input"/>

    <p:store method="xml" encoding="UTF-8" omit-xml-declaration="false">
        <p:with-option name="indent" select="$indent eq 'true'"/>
        <p:with-option name="href" select="$href"/>
    </p:store>
        
    <!-- Pass the original input as output: -->
    <p:identity>
        <p:input port="source"><p:pipe port="result" step="original-input"/></p:input>
    </p:identity>
</p:declare-step>
