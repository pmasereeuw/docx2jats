<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pcm="http://www.masereeuw.nl/xslt/3.0/functions"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:variable name="nl" as="xs:string" select="'&#10;'"/>
    <xsl:variable name="apos" as="xs:string" select="''''"/>
    
    <!-- This string contains the first line of the script that is to be generated. -->
    <xsl:param name="first-shellscript-line" as="xs:string" select="concat('#!/bin/bash', $nl)"/>
    
    <!-- This strings marks a comment. -->
    <xsl:param name="comment-string" as="xs:string" select="'# '"/>
    
    <!-- Retrieval command that is to be generated, the string %url% will be replaced by the URL to be retrieved and the string %file% by the name
         of the output file. Both %url% and %file% should be present.
    -->
    <xsl:param name="wget-command-string" as="xs:string" select="concat('wget --quiet --no-clobber $', $apos, '%url%', $apos, ' --output-document=%file%')"/> <!-- bash: $'..' is de ultieme manier om een string niet te laten interpreteren -->
        
    <!-- Creates a simple command line, effectively only adding a new line to the end of the command. -->
    <xsl:function name="pcm:create-simple-command-line" as="xs:string">
        <xsl:param name="command" as="xs:string"/>
        <xsl:value-of select="concat($command, $nl)"/>
    </xsl:function>

    <!-- Creates a command line, replacing the strings %url% and %file% with the values of the corresponding parameters. -->
    <xsl:function name="pcm:create-url-to-file-command-line" as="xs:string">
        <xsl:param name="url" as="xs:string"/>
        <xsl:param name="outputfilename" as="xs:string"/>
        <xsl:value-of select="concat(replace(replace($wget-command-string, '%url%', $url), '%file%', $outputfilename), $nl)"/>
    </xsl:function>
    
    <xsl:function name="pcm:create-comment-line" as="xs:string">
        <xsl:param name="comment" as="xs:string"/>
        <xsl:value-of select="concat($comment-string, translate($comment, '&#9;&#10;&#13;', '&#32;&#32;&#32;'), $nl)"/>
    </xsl:function>
    
    <!-- The filename part of a pathname, including the extension. -->
    <xsl:function name="pcm:get-base-filename" as="xs:string">
        <xsl:param name="path" as="xs:string"/>
        <xsl:value-of select="replace($path, '^(.*/)?([^/]+)/?$','$2')"/>
    </xsl:function>
    
    <!-- The directory part of a pathname. -->
    <xsl:function name="pcm:get-directory-name" as="xs:string">
        <xsl:param name="path" as="xs:string"/>
        <xsl:variable name="dir" as="xs:string" select="replace($path, '^(.*/)?([^/]+)/?$','$1')"/>
        <xsl:value-of select="if ($dir eq '') then '.' else $dir"/>
    </xsl:function>
    
    <!-- Return the pathname without the file extension (also excluding the "."). -->
    <xsl:function name="pcm:strip-file-extension" as="xs:string">
        <xsl:param name="path" as="xs:string"/>
        <xsl:value-of select="replace($path, '^((.*/)?([^/]+))\.[^./]+$', '$1')"/>
    </xsl:function>
    
    <!-- Returns the extension of the pathname, without the ".". -->
    <xsl:function name="pcm:get-file-extension" as="xs:string">
        <xsl:param name="path" as="xs:string"/>
        <!-- The extra condition with matches() is needed because otherwise a filename without dot will lead to the filename
             being returned instead of an empty string.
        -->
        <xsl:value-of select="if (matches($path, '^.*\.[^./]+$')) then replace($path, '^.*\.([^./]+)$', '$1') else ''"/>
    </xsl:function>
    
    <xsl:function name="pcm:get-uuid" as="xs:string">
        <xsl:value-of select="uuid:randomUUID()" xmlns:uuid="java:java.util.UUID"/>
    </xsl:function>
</xsl:stylesheet>