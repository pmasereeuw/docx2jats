<?xml version="1.0" encoding="UTF-8"?>
<p:library
    version="1.0"
    xmlns:p="http://www.w3.org/ns/xproc"
    xmlns:c="http://www.w3.org/ns/xproc-step"
    xmlns:pcm="http://www.masereeuw.nl/xslt/3.0/functions">
    
    <p:documentation>
        This step uses a Calabash extension to copy images from one place to another. The input image path is specified using the required option absoluteURIOfInputImage. As the
        name suggests, this should be an absolute filename.
        The output image filename is supplied using the required outputImageFilename option. Its value may either be relative or absolute.
    </p:documentation>
    
    <p:declare-step type="pcm:copy-image" name="copy-image">
        <p:option name="absoluteURIOfInputImage" required="true">
            <p:documentation>The absoluteURIOfInputImage option contains the absolute URI of the input image (the p:make-absolute-uris step may be useful here).</p:documentation>
        </p:option>
        <p:option name="outputImageFilename">
            <p:documentation>The outputImageFilename contains the filename of the copy that will be made of the input image. It it upto the caller to decide if
            the name should be relative or absolute. Also, it is the callers responsability to supply a correct path and a correct file name.</p:documentation>
        </p:option>
        
        <p:identity name="create-http-request">
            <p:documentation>
                This creates the request "object" for use by p:http-request. Note the absence of @href - the recommendation gives it a static
                value, so the next step is to add the attribute dynamically by means of p:add-attribute. Somewhat verbose, not to say cumbersome.
            </p:documentation>
            <p:input port="source">
                <p:inline>
                    <c:request method="GET"/>
                </p:inline>
            </p:input>
        </p:identity>
        
        <p:add-attribute name="set-uri" match="/c:request" attribute-name="href">
            <p:with-option name="attribute-value" select="$absoluteURIOfInputImage"/>
        </p:add-attribute>
        
        <p:http-request method="GET" name="http-request-image">
            <p:documentation>
                The input for this step is the c:request "object" that has been created in the lines above.
                Note that the value of the href attribute may be a file - the Calabash implementation supports the local file protocol.
                Binary files are converted to a BASE64 encoding before being sent to the output port.
            </p:documentation>
        </p:http-request>
        
        <p:store cx:decode="true" xmlns:cx="http://xmlcalabash.com/ns/extensions" name="store-image-file">
            <p:documentation>
                This step takes the output of the previous step and stores it to a file. It makes use of an extension of the standard. The W3C
                suggests that implementors provide a way to convert BASE64 input to binary format. The suggestion is to pass the following attribute:
                method="ext:binary". The Calabash implementation, however, decided to use cs:decode="true".
            </p:documentation>
            <p:with-option name="href" select="$outputImageFilename"/>
        </p:store>
    </p:declare-step>
</p:library>