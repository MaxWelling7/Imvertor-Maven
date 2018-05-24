<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    SVN: $Id:  Imvert2XSD-KING-endproduct-xml.xsl 7509 2016-04-25 13:30:29Z arjan $ 
-->
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:UML="omg.org/UML1.3"
    
    xmlns:imvert="http://www.imvertor.org/schema/system"
    xmlns:imf="http://www.imvertor.org/xsl/functions"
    xmlns:imvert-result="http://www.imvertor.org/schema/imvertor/application/v20160201"
    xmlns:ep="http://www.imvertor.org/schema/endproduct"
    
    version="2.0">
    
    <!--TODO: Kijken of de volgende imports en include nog wel nodig zijn. -->
    <xsl:import href="../common/Imvert-common.xsl"/>
    <xsl:import href="../common/Imvert-common-validation.xsl"/>
    <xsl:import href="../common/extension/Imvert-common-text.xsl"/>   
    <xsl:import href="../common/Imvert-common-derivation.xsl"/>
    <xsl:import href="Imvert2XSD-KING-common.xsl"/>

    <xsl:include href="Imvert2XSD-KING-common-checksum.xsl"/>
    
    <xsl:output indent="yes" method="xml" encoding="UTF-8"/>
    
    <!-- TODO: Kijken of de volgende key's wel nodig zijn. -->
    <xsl:key name="class" match="imvert:class" use="imvert:id" />
    <xsl:key name="enumerationClass" match="imvert:class" use="imvert:name" />
    <!-- This key is used within the for-each instruction further in this code. -->
    <xsl:key name="construct-id" match="ep:construct" use="concat(ep:id,@verwerkingsModus)" />
    <xsl:key name="construct-id-in-vrijbericht" match="ep:construct" use="concat(ep:id,@verwerkingsModus,@entiteitOrBerichtRelatie)" />
    
    
    <xsl:variable name="stylesheet-code" as="xs:string">OAS</xsl:variable>
    <xsl:variable name="debugging" select="imf:debug-mode($stylesheet-code)" as="xs:boolean"/>
    
    <xsl:variable name="stylesheet" as="xs:string">Imvert2XSD-KING-OpenAPI-endproduct-xml</xsl:variable>
    <xsl:variable name="stylesheet-version" as="xs:string">$Id: Imvert2XSD-KING-OpenAPI-endproduct-xml.xsl 7509 2016-04-25 13:30:29Z arjan $</xsl:variable>  

    <!-- TODO: Kijken welke van de volgende variabeles nog nodig zijn. -->
    <xsl:variable name="GML-prefix" select="'gml'"/>
    
    <xsl:variable name="config-schemarules">
        <xsl:sequence select="imf:get-config-schemarules()"/>
    </xsl:variable> 
    <xsl:variable name="config-tagged-values">
        <xsl:sequence select="imf:get-config-tagged-values()"/>
    </xsl:variable> 

    <xsl:variable name="messages" select="imf:document(imf:get-config-string('properties','RESULT_METAMODEL_KINGBSM_XSD_MIGRATE'))"/>  
    <xsl:variable name="packages" select="$messages/imvert:packages"/>

    <xsl:variable name="imvert-document" select="if (exists($messages/imvert:packages)) then $messages else ()"/>
    
    <!-- needed for disambiguation of duplicate attribute names -->
    <xsl:variable name="all-simpletype-attributes" select="$packages//imvert:attribute[empty(imvert:type)]"/> 

    <xsl:variable name="version" select="$packages/imvert:version"/>
    
    <xsl:variable name="endproduct">
        <xsl:apply-templates select="/ep:rough-messages"/>       
    </xsl:variable>
    
    <!-- Starts the creation of the rough-message constructs and the constructs relates to those message constructs. -->
    <xsl:template match="ep:rough-messages">
        <ep:message-sets>
            <ep:message-set KV-namespace = "yes">
                <xsl:sequence select="imf:create-debug-comment('Debuglocation OAS00100',$debugging)"/>
                
                <xsl:sequence select="imf:create-output-element('ep:name', $packages/imvert:application)"/>
                <xsl:sequence select="imf:create-output-element('ep:release', $packages/imvert:release)"/>
                <xsl:sequence select="imf:create-output-element('ep:date', substring-before($packages/imvert:generated,'T'))"/>
                <xsl:sequence select="imf:create-output-element('ep:patch-number', $version)"/>
                
                <xsl:if test="$debugging">
                    <xsl:sequence select="imf:debug-document($config-schemarules,'imvert-schema-rules.xml',true(),false())"/>
                    <xsl:sequence select="imf:debug-document($config-tagged-values,'imvert-tagged-values.xml',true(),false())"/>
                </xsl:if>
                
                <xsl:sequence select="imf:track('Constructing the OpenAPI message constructs')"/>
                
                <xsl:sequence select="imf:create-debug-comment('Debuglocation OAS00200',$debugging)"/>
                <xsl:apply-templates select="ep:rough-message"/>

                <xsl:sequence select="imf:track('Constructing the constructs related to the OpenAPI messages')"/>
                
                <!-- xxxxx -->
                <xsl:sequence select="imf:create-debug-comment('Debuglocation OAS00250',$debugging)"/>
                <xsl:for-each-group 
                    select="//ep:construct[@type!='complex-datatype']" 
                    group-by="ep:name">
                    <xsl:sequence select="imf:create-debug-comment('Debuglocation OAS00300',$debugging)"/>
                    <xsl:apply-templates select="current-group()[1]" mode="as-type"/>
                </xsl:for-each-group>
                <xsl:sequence select="imf:create-debug-comment('Debuglocation OAS00275',$debugging)"/>
                <xsl:for-each-group 
                    select="//ep:construct[@type='complex-datatype']" 
                    group-by="ep:type-id">
                    <xsl:sequence select="imf:create-debug-comment('Debuglocation OAS00350',$debugging)"/>
                    <xsl:apply-templates select="current-group()[1]" mode="as-type"/>
                </xsl:for-each-group>
                <!-- Following apply creates all global ep:constructs conatining enumeration lists. -->
                <xsl:apply-templates select="$packages//imvert:package[not(contains(imvert:alias,'/www.kinggemeenten.nl/BSM/Berichtstrukturen'))]/
                                             imvert:class[imf:get-stereotype(.) = ('stereotype-name-enumeration') and generate-id(.) = 
                                             generate-id(key('enumerationClass',imvert:name,$packages)[1])]" mode="mode-global-enumeration"/>
            </ep:message-set>
        </ep:message-sets>
    </xsl:template>
    
    <!-- Takes care of processing individual ep:rough-message elements to ep:message elements. -->
    <xsl:template match="ep:rough-message">
        <xsl:sequence select="imf:create-debug-comment('Debuglocation OAS00400',$debugging)"/>
        
        <xsl:variable name="currentMessage" select="."/>
        <xsl:variable name="id" select="ep:id" as="xs:string"/>
        <xsl:variable name="message-construct" select="imf:get-class-construct-by-id($id,$packages)"/>
        
        <!-- TODO: UItzoeken of documentation gewenst is. -->
        <xsl:variable name="doc">





            <xsl:variable name="this-construct" select="$packages//imvert:*[imvert:id = $id]"/>
            <xsl:if test="not(empty(imf:merge-documentation($this-construct,'CFG-TV-DEFINITION')))">
                <ep:definition>
                    <xsl:sequence select="imf:merge-documentation($this-construct,'CFG-TV-DEFINITION')"/>
                </ep:definition>
            </xsl:if>
            <xsl:if test="not(empty(imf:merge-documentation($this-construct,'CFG-TV-DESCRIPTION')))">
                <ep:description>
                    <xsl:sequence select="imf:merge-documentation($this-construct,'CFG-TV-DESCRIPTION')"/>
                </ep:description>
            </xsl:if>
            <xsl:if test="not(empty(imf:get-most-relevant-compiled-taggedvalue($this-construct, '##CFG-TV-PATTERN')))">
                <ep:pattern>
                    <ep:p>
                        <xsl:sequence select="imf:get-most-relevant-compiled-taggedvalue($this-construct, '##CFG-TV-PATTERN')"/>
                    </ep:p>
                </ep:pattern>
            </xsl:if>
            




<?x            <xsl:if test="not(empty(imf:merge-documentation(.,'CFG-TV-DEFINITION')))">
                <ep:definition>
                    <xsl:sequence select="imf:merge-documentation(.,'CFG-TV-DEFINITION')"/>
                </ep:definition>
            </xsl:if>
            <xsl:if test="not(empty(imf:merge-documentation(.,'CFG-TV-DESCRIPTION')))">
                <ep:description>
                    <xsl:sequence select="imf:merge-documentation(.,'CFG-TV-DESCRIPTION')"/>
                </ep:description>
            </xsl:if>
            <xsl:if test="not(empty(imf:get-most-relevant-compiled-taggedvalue(., '##CFG-TV-PATTERN')))">
                <ep:pattern>
                    <ep:p>
                        <xsl:sequence select="imf:get-most-relevant-compiled-taggedvalue(., '##CFG-TV-PATTERN')"/>
                    </ep:p>
                </ep:pattern>
            </xsl:if>
?>
            
        </xsl:variable>
        <xsl:variable name="expand" select="imf:get-most-relevant-compiled-taggedvalue(., '##CFG-TV-EXPAND')"/>
        <xsl:variable name="fields" select="imf:get-most-relevant-compiled-taggedvalue(., '##CFG-TV-FIELDS')"/>
        <xsl:variable name="grouping" select="imf:get-most-relevant-compiled-taggedvalue(., '##CFG-TV-GROUPING')"/>
        <xsl:variable name="pagination" select="imf:get-most-relevant-compiled-taggedvalue(., '##CFG-TV-PAGE')"/>
        <xsl:variable name="serialisation" select="imf:get-most-relevant-compiled-taggedvalue(., '##CFG-TV-SERIALISATION')"/>
        <xsl:variable name="sort" select="imf:get-most-relevant-compiled-taggedvalue(., '##CFG-TV-SORT')"/>
        
        <xsl:variable name="name" select="$message-construct/imvert:name/@original" as="xs:string"/>
        <xsl:variable name="tech-name" select="imf:get-normalized-name($message-construct/imvert:name, 'element-name')" as="xs:string"/>

        <!-- TODO: Nagaan of het wel noodzakelijk is om over de min- en maxoccurs van de entiteitrelaties te kunnen beschikken. -->
        <xsl:variable name="minOccursAssociation">
            <xsl:choose>
                <xsl:when test="count($message-construct//imvert:associations/imvert:association[not(imvert:name = 'stuurgegevens') and not(imvert:name = 'parameters') and not(imvert:name = 'start') and not(imvert:name = 'scope') and not(imvert:name = 'vanaf') and not(imvert:name = 'tot en met')]) = 0">
                    <xsl:variable name="msg"
                        select="concat('The class ',ep:name,' (id ',ep:id,') does not have an association with a min-occurs.')"/>
                    <xsl:sequence select="imf:msg('WARNING', $msg)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$message-construct//imvert:associations/imvert:association[not(imvert:name = 'stuurgegevens') and not(imvert:name = 'parameters') and not(imvert:name = 'start') and not(imvert:name = 'scope') and not(imvert:name = 'vanaf') and not(imvert:name = 'tot en met')]/imvert:min-occurs"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="maxOccursAssociation">
            <xsl:choose>
                <xsl:when test="count($message-construct//imvert:associations/imvert:association[not(imvert:name = 'stuurgegevens') and not(imvert:name = 'parameters') and not(imvert:name = 'start') and not(imvert:name = 'scope') and not(imvert:name = 'vanaf') and not(imvert:name = 'tot en met')]) = 0">
                    <xsl:variable name="msg"
                        select="concat('The class ',ep:name,' (id ',ep:id,')does not have an association with a max-occurs.')"/>
                    <xsl:sequence select="imf:msg('WARNING', $msg)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$message-construct//imvert:associations/imvert:association[not(imvert:name = 'stuurgegevens') and not(imvert:name = 'parameters') and not(imvert:name = 'start') and not(imvert:name = 'scope') and not(imvert:name = 'vanaf') and not(imvert:name = 'tot en met')]/imvert:max-occurs"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
<?x        <xsl:result-document href="{concat('file:/c:/temp/construct-',ep:id,'-',generate-id(),'.xml')}">
            <xsl:copy-of select="$message-construct"/>
        </xsl:result-document>    ?>

        <xsl:sequence select="imf:create-debug-comment('Debuglocation OAS00500',$debugging)"/>
        
        <ep:message expand="{$expand}" fields="{$fields}" grouping="{$grouping}" pagination="{$pagination}" serialisation="{$serialisation}" sort="{$sort}">
            <xsl:sequence select="imf:create-output-element('ep:name', $name)"/>
            <xsl:sequence select="imf:create-output-element('ep:tech-name', $tech-name)"/>
            <xsl:sequence select="imf:create-output-element('ep:documentation', $doc,'',false(),false())"/>
            <xsl:if test=".//ep:construct">
                <xsl:sequence select="imf:create-debug-comment('Debuglocation OAS00600',$debugging)"/>
                <ep:seq>
                    <!-- TODO: Zolang niet duidelijk is of min- en maxoccurs noodzakelijk zijn. Geven we in de aanroep naar het construct template de waarde '-' 
                         mee als teken dat deze niet gegenereerd hoeven te worden. -->
<?x                    <xsl:apply-templates select="ep:construct" mode="as-content">
                        <xsl:with-param name="minOccurs" select="$minOccursAssociation"/>
                        <xsl:with-param name="maxOccurs" select="$maxOccursAssociation"/>
                    </xsl:apply-templates> ?>
                    <xsl:apply-templates select="ep:construct" mode="as-content">
                        <xsl:with-param name="minOccurs" select="'-'"/>
                        <xsl:with-param name="maxOccurs" select="'-'"/>
                    </xsl:apply-templates>
                </ep:seq> 
            </xsl:if>
        </ep:message>
    </xsl:template>
    
    <xsl:template match="ep:construct" mode="as-content">
        <xsl:param name="minOccurs"/>
        <xsl:param name="maxOccurs"/>

        <xsl:variable name="name" select="ep:name" as="xs:string"/>
        <xsl:variable name="tech-name" select="imf:get-normalized-name(ep:tech-name, 'element-name')" as="xs:string"/>
       <!-- Sometime we like to process the imvert construct which has a reference to a class and sometime the class.
            For that reason the 'id' variable sometimes gets the value of the imvert:id element of the association, sometimes of the attribute
            and sometimes of the class. --> 
        <xsl:variable name="id">
            <xsl:choose>
                <xsl:when test="ep:id and @type = ('association','groepCompositie','association-class')">
                    <xsl:value-of select="ep:id"/>
                </xsl:when>
                <xsl:when test="ep:id-refering-association and @type = 'class'">
                    <xsl:value-of select="ep:id-refering-association"/>
                </xsl:when>
                <xsl:when test="ep:id and @type = 'class'">
                    <xsl:variable name="id" select="ep:id"/>
                    <xsl:value-of select="$packages//imvert:association[imvert:type-id = $id][1]/imvert:id"/>
                </xsl:when>
                <xsl:when test="ep:id and @type = 'subclass'">
                    <xsl:value-of select="ep:id"/>
                </xsl:when>
                <xsl:when test="ep:id and @type = 'attribute'">
                    <xsl:variable name="id" select="ep:id"/>
                    <xsl:value-of select="$packages//imvert:attribute[imvert:type-id = $id][1]/imvert:id"/>
                </xsl:when>
                <xsl:when test="ep:type-id and @type = 'complex-datatype'">
                    <xsl:variable name="type-id" select="ep:type-id"/>
                    <xsl:value-of select="$packages//imvert:attribute[imvert:type-id = $type-id][1]/imvert:id"/>
                </xsl:when>
                <xsl:when test="ep:type-id">
                    <xsl:variable name="type-id" select="ep:type-id"/>
                    <xsl:value-of select="$packages//imvert:association[imvert:type-id = $type-id]/imvert:id"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <!-- It's not possible to get debug information which is set into a variable into the output we do this outside the variable.
             The 'when' statements catch all situation as the when statements in the variable above. -->
        <xsl:if test="$debugging">
            <xsl:choose>
                <xsl:when test="ep:id and @type = 'association'">
                    <xsl:sequence select="imf:create-debug-comment(concat('OAS00700, id: ',$id),$debugging)"/>
                </xsl:when>
                <xsl:when test="ep:id and @type = 'groepCompositie'">
                    <xsl:sequence select="imf:create-debug-comment(concat('OAS00750, id: ',$id),$debugging)"/>
                </xsl:when>
                <xsl:when test="ep:id and @type = 'association-class'">
                    <xsl:sequence select="imf:create-debug-comment(concat('OAS00800, id: ',$id),$debugging)"/>
                </xsl:when>
                <xsl:when test="ep:id-refering-association and @type = 'class'">
                    <xsl:sequence select="imf:create-debug-comment(concat('OAS00825, id: ',$id),$debugging)"/>
                </xsl:when>
                <xsl:when test="ep:id and @type = 'class'">
                    <xsl:sequence select="imf:create-debug-comment(concat('OAS00850, id: ',$id),$debugging)"/>
                </xsl:when>
                <xsl:when test="ep:id and @type = 'subclass'">
                    <xsl:sequence select="imf:create-debug-comment(concat('OAS00900, id: ',$id),$debugging)"/>
                </xsl:when>
                <xsl:when test="ep:id and @type = 'attribute'">
                    <xsl:sequence select="imf:create-debug-comment(concat('OAS00950, id: ',$id),$debugging)"/>
                </xsl:when>
                <xsl:when test="ep:type-id and @type = 'complex-datatype'">
                    <xsl:sequence select="imf:create-debug-comment(concat('OAS01000, id: ',$id),$debugging)"/>
                </xsl:when>
                <xsl:when test="ep:type-id">
                    <xsl:sequence select="imf:create-debug-comment(concat('OAS01050, id: ',$id),$debugging)"/>
                </xsl:when>
            </xsl:choose>

            <xsl:choose>
                <xsl:when test="ep:id and @type = 'association'">
                    <xsl:sequence select="imf:msg('WARNING','OAS00700')"/>
                </xsl:when>
                <xsl:when test="ep:id and @type = 'groepCompositie'">
                    <xsl:sequence select="imf:msg('WARNING','OAS00750')"/>
                </xsl:when>
                <xsl:when test="ep:id and @type = 'association-class'">
                    <xsl:sequence select="imf:msg('WARNING','OAS00800')"/>
                </xsl:when>
                <xsl:when test="ep:id-refering-association and @type = 'class'">
                    <xsl:sequence select="imf:msg('WARNING','OAS00825')"/>
                </xsl:when>
                <xsl:when test="ep:id and @type = 'class'">
                    <xsl:sequence select="imf:msg('WARNING','OAS00850')"/>
                </xsl:when>
                <!-- TOD: Nagaan of deze when correct is. Wordt nl. niet in een when statement in bovenstaande variable afgevangen. -->
                <xsl:when test="ep:id and @type = 'subclass'">
                    <xsl:sequence select="imf:msg('WARNING','OAS00900')"/>
                </xsl:when>
                <xsl:when test="ep:id and @type = 'attribute'">
                    <xsl:sequence select="imf:msg('WARNING','OAS00950')"/>
                </xsl:when>
                <xsl:when test="ep:type-id and @type = 'complex-datatype'">
                    <xsl:sequence select="imf:msg('WARNING','OAS01000')"/>
                </xsl:when>
                <xsl:when test="ep:type-id">
                    <xsl:sequence select="imf:msg('WARNING','OAS01050')"/>
                </xsl:when>
            </xsl:choose>
        </xsl:if>

        <!-- The construct variable holds the imvert construct which has an imvert:id equal to the 'id' variable. So sometimes it's an attribute, sometimes 
             an association amd sometimes a class. -->
        <xsl:variable name="construct" select="imf:get-construct-by-id($id,$packages)"/>

<?x        <xsl:variable name="doc">
            <xsl:variable name="this-construct" select="$packages//imvert:*[imvert:id = $id]"/>
            <xsl:if test="not(empty(imf:merge-documentation($this-construct,'CFG-TV-DEFINITION')))">
                <ep:definition>
                    <xsl:sequence select="imf:merge-documentation($this-construct,'CFG-TV-DEFINITION')"/>
                </ep:definition>
            </xsl:if>
            <xsl:if test="not(empty(imf:merge-documentation($this-construct,'CFG-TV-DESCRIPTION')))">
                <ep:description>
                    <xsl:sequence select="imf:merge-documentation($this-construct,'CFG-TV-DESCRIPTION')"/>
                </ep:description>
            </xsl:if>
            <xsl:if test="not(empty(imf:get-most-relevant-compiled-taggedvalue($this-construct, '##CFG-TV-PATTERN')))">
                <ep:pattern>
                    <ep:p>
                        <xsl:sequence select="imf:get-most-relevant-compiled-taggedvalue($this-construct, '##CFG-TV-PATTERN')"/>
                    </ep:p>
                </ep:pattern>
            </xsl:if>
        </xsl:variable> ?>
<?x        <xsl:result-document href="{concat('file:/c:/temp/construct-',$name,'-',generate-id(),'.xml')}">
            <xsl:copy-of select="$construct"/>
        </xsl:result-document>    ?>
        
        <xsl:choose>
            <!-- If the current ep:construct is an association-class no ep:construct element is generated. All attributes of that related class are directly placed 
                 within the current ep:construct. Also the child ep:superconstructs and ep:constructs (if present) are processed. -->
            <xsl:when test="@type='association-class'">
                <xsl:sequence select="imf:create-debug-comment(concat('OAS01100, id: ',$id),$debugging)"/>
                <xsl:apply-templates select="$construct//imvert:attributes/imvert:attribute"/>
                <xsl:apply-templates select="ep:superconstruct" mode="as-content"/>
                <xsl:apply-templates select="ep:construct" mode="as-content"/>
            </xsl:when>
            <!-- If the current ep:construct is an complex-datatype a ep:construct element is generated with all necessary properties. -->
            <xsl:when test="@type='complex-datatype'">
                <xsl:variable name="type-id" select="ep:type-id"/>
                <xsl:variable name="classconstruct" select="imf:get-construct-by-id($type-id,$packages)"/>
                <xsl:variable name="type-name" select="$classconstruct/imvert:name"/>
                <ep:construct type="{@type}">
                    <xsl:sequence select="imf:create-debug-comment(concat('OAS01150, id: ',$id),$debugging)"/>
                    <xsl:sequence select="imf:create-output-element('ep:name', $name)"/>
                    <xsl:sequence select="imf:create-output-element('ep:tech-name', $tech-name)"/>
<?x                    <xsl:sequence select="imf:create-output-element('ep:documentation', $doc,'',false(),false())"/> ?>
                    <xsl:sequence select="imf:create-output-element('ep:min-occurs', $construct/imvert:min-occurs)"/>
                    <xsl:sequence select="imf:create-output-element('ep:max-occurs', $construct/imvert:max-occurs)"/>
                    <xsl:sequence select="imf:create-output-element('ep:type-name', imf:get-normalized-name($type-name,'type-name'))"/>            
                </ep:construct> 
            </xsl:when>
            <!-- If the current ep:construct is an association or an groupCompositie a ep:construct element is generated with all necessary properties.
                 This when statement differs from the one above by the value of the ep:name and ep:tech-name. -->
            <xsl:when test="@type=('association','groepCompositie')">
                <xsl:variable name="type-id" select="ep:type-id"/>
                <xsl:variable name="classconstruct" select="imf:get-construct-by-id($type-id,$packages)"/>
                <xsl:variable name="type-name" select="$classconstruct/imvert:name"/>
                <ep:construct type="{@type}">
                    <xsl:sequence select="imf:create-debug-comment(concat('OAS01200, id: ',$id),$debugging)"/>
                    <xsl:sequence select="imf:create-output-element('ep:name', $type-name)"/>
                    <xsl:sequence select="imf:create-output-element('ep:tech-name', $type-name)"/>
<?x                    <xsl:sequence select="imf:create-output-element('ep:documentation', $doc,'',false(),false())"/> ?>
                    <xsl:sequence select="imf:create-output-element('ep:min-occurs', $construct/imvert:min-occurs)"/>
                    <xsl:sequence select="imf:create-output-element('ep:max-occurs', $construct/imvert:max-occurs)"/>
                    <xsl:sequence select="imf:create-output-element('ep:type-name', imf:get-normalized-name($type-name,'type-name'))"/>            
                </ep:construct> 
            </xsl:when>
            <!-- In all othert cases this branch applies. -->
            <xsl:otherwise>
                <ep:construct type="{@type}">
                    <xsl:sequence select="imf:create-debug-comment(concat('OAS01250, id: ',$id),$debugging)"/>
                    <xsl:sequence select="imf:create-output-element('ep:name', $name)"/>
                    <xsl:sequence select="imf:create-output-element('ep:tech-name', $tech-name)"/>
<?x                    <xsl:sequence select="imf:create-output-element('ep:documentation', $doc,'',false(),false())"/> ?>
                    <!-- Depending on the type the min- and max-occurs are set or aren't set at all. -->
                    <xsl:choose>
                        <xsl:when test="@type = 'subclass'">
                            <xsl:sequence select="imf:create-debug-comment(concat('OAS01300, id: ',$id),$debugging)"/>
                            <xsl:sequence select="imf:create-output-element('ep:min-occurs', 0)"/>
                            <xsl:sequence select="imf:create-output-element('ep:max-occurs', 1)"/>
                        </xsl:when>
                        <xsl:when test="$minOccurs = '-'">
                            <xsl:sequence select="imf:create-debug-comment(concat('OAS01350, id: ',$id),$debugging)"/>
                        </xsl:when>
                        <xsl:when test="not($minOccurs = '')">
                            <xsl:sequence select="imf:create-debug-comment(concat('OAS01400, id: ',$id),$debugging)"/>
                            <xsl:sequence select="imf:create-output-element('ep:min-occurs', $minOccurs)"/>
                            <xsl:sequence select="imf:create-output-element('ep:max-occurs', $maxOccurs)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="imf:create-debug-comment(concat('OAS01450, id: ',$id),$debugging)"/>
                            <xsl:sequence select="imf:create-output-element('ep:min-occurs', $construct/imvert:min-occurs)"/>
                            <xsl:sequence select="imf:create-output-element('ep:max-occurs', $construct/imvert:max-occurs)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:sequence select="imf:create-output-element('ep:type-name', imf:get-normalized-name($tech-name,'type-name'))"/>            
                </ep:construct>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
        
    <!-- Processing of an ep:superconstruct means all attributes of that related class are directly placed 
         within the current ep:construct. Also the child ep:superconstructs and ep:constructs (if present) are processed. -->
    <xsl:template match="ep:superconstruct" mode="as-content">
        
        <xsl:variable name="id" select="ep:id"/>
        <xsl:variable name="construct" select="imf:get-construct-by-id($id,$packages)"/>
        <xsl:sequence select="imf:create-debug-comment(concat('OAS01500, id: ',$id),$debugging)"/>
        
        <xsl:apply-templates select="$construct//imvert:attributes/imvert:attribute"/>
        <xsl:apply-templates select="ep:superconstruct" mode="as-content"/>
        <xsl:apply-templates select="ep:construct" mode="as-content"/>

    </xsl:template>
    
    <!-- This template processes al ep:constructs refered to form the ep:message constructs and refered to from these constructs itself. -->
    <xsl:template match="ep:construct" mode="as-type">
        <xsl:variable name="name" select="ep:name" as="xs:string"/>
        <xsl:variable name="tech-name" select="imf:get-normalized-name(ep:tech-name, 'element-name')" as="xs:string"/>
        <xsl:variable name="id" select="ep:id"/>
        <xsl:variable name="type-id" select="ep:type-id"/>
        <xsl:variable name="construct">
            <xsl:choose>
                <xsl:when test="not(empty($type-id))">
                    <xsl:variable name="this-construct" select="imf:get-construct-by-id($type-id,$packages)"/>
                    <xsl:sequence select="$this-construct"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="this-construct" select="imf:get-construct-by-id($id,$packages)"/>
                    <xsl:sequence select="$this-construct"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="empty($id) and empty($type-id)">
                <xsl:variable name="msg" select="concat('Het construct ',$name,' heeft geen id en geen type-id.')" as="xs:string"/>
                <xsl:sequence select="imf:msg('WARNING',$msg)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:result-document href="{concat('file:/c:/temp/construct-',$name,'-',generate-id(),'.xml')}">
                    <xsl:sequence select="$construct"/>
                </xsl:result-document>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:variable name="doc">
            <xsl:choose>
                <xsl:when test="not(empty($type-id))">
                    <xsl:variable name="this-construct" select="$packages//imvert:*[imvert:id = $type-id]"/>
                    <xsl:if test="not(empty(imf:merge-documentation($this-construct,'CFG-TV-DEFINITION')))">
                        <ep:definition>
                            <xsl:sequence select="imf:merge-documentation($this-construct,'CFG-TV-DEFINITION')"/>
                        </ep:definition>
                    </xsl:if>
                    <xsl:if test="not(empty(imf:merge-documentation($this-construct,'CFG-TV-DESCRIPTION')))">
                        <ep:description>
                            <xsl:sequence select="imf:merge-documentation($this-construct,'CFG-TV-DESCRIPTION')"/>
                        </ep:description>
                    </xsl:if>
                    <xsl:if test="not(empty(imf:get-most-relevant-compiled-taggedvalue($this-construct, '##CFG-TV-PATTERN')))">
                        <ep:pattern>
                            <ep:p>
                                <xsl:sequence select="imf:get-most-relevant-compiled-taggedvalue($this-construct, '##CFG-TV-PATTERN')"/>
                            </ep:p>
                        </ep:pattern>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="this-construct" select="$packages//imvert:*[imvert:id = $id]"/>
                    <xsl:if test="not(empty(imf:merge-documentation($this-construct,'CFG-TV-DEFINITION')))">
                        <ep:definition>
                            <xsl:sequence select="imf:merge-documentation($this-construct,'CFG-TV-DEFINITION')"/>
                        </ep:definition>
                    </xsl:if>
                    <xsl:if test="not(empty(imf:merge-documentation($this-construct,'CFG-TV-DESCRIPTION')))">
                        <ep:description>
                            <xsl:sequence select="imf:merge-documentation($this-construct,'CFG-TV-DESCRIPTION')"/>
                        </ep:description>
                    </xsl:if>
                    <xsl:if test="not(empty(imf:get-most-relevant-compiled-taggedvalue($this-construct, '##CFG-TV-PATTERN')))">
                        <ep:pattern>
                            <ep:p>
                                <xsl:sequence select="imf:get-most-relevant-compiled-taggedvalue($this-construct, '##CFG-TV-PATTERN')"/>
                            </ep:p>
                        </ep:pattern>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <!-- ep:constructs of type 'association-class' aren't processed at all.
                 The content of that kind of constructs is already embedded within its parents constructs. -->
            <xsl:when test="@type='association-class'"/>
            <xsl:when test="@type='association' and $construct//imvert:attributes/imvert:attribute">
                <xsl:sequence select="imf:create-debug-comment(concat('OAS01600, id: ',$id),$debugging)"/>
                <xsl:copy>
                    <xsl:attribute name="type" select="@type"/>
                    <xsl:sequence select="imf:create-output-element('ep:name', $name)"/>
                    <xsl:sequence select="imf:create-output-element('ep:tech-name', imf:get-normalized-name($tech-name,'type-name'))"/>      
                    <xsl:sequence select="imf:create-output-element('ep:documentation', $doc,'',false(),false())"/>
                    <ep:seq>
                        <xsl:sequence select="imf:create-debug-comment(concat('OAS01620, id: ',$id),$debugging)"/>
                        <xsl:apply-templates select="$construct//imvert:attributes/imvert:attribute"/>
                        <xsl:sequence select="imf:create-debug-comment(concat('OAS01640, id: ',$id),$debugging)"/>                   
                        <xsl:apply-templates select="ep:superconstruct" mode="as-content"/>
                        <xsl:sequence select="imf:create-debug-comment(concat('OAS01660, id: ',$id),$debugging)"/>
                        <xsl:apply-templates select="ep:construct[@type!='class']" mode="as-content"/>
                        <xsl:sequence select="imf:create-debug-comment(concat('OAS01680, id: ',$id),$debugging)"/>
                    </ep:seq>
                </xsl:copy>
            </xsl:when>
            <!-- if the ep:constructs itself has a ep:construct or ep:superconstruct or if it is of type 'class' and that class has attributes it is processed here.
                 The ep:construct is replicated and ep:constructs for imvert:attributes relates to that construct are placed. 
                 Also the child ep:superconstructs and ep:constructs (if present) are processed. -->
            <xsl:when test="ep:construct or ep:superconstruct or (@type='class' and $construct//imvert:attributes/imvert:attribute)">
                <xsl:sequence select="imf:create-debug-comment(concat('OAS01700, id: ',$id),$debugging)"/>
                <xsl:variable name="type">
                    <xsl:choose>
                        <xsl:when test="@type = 'subclass'">
                            <xsl:value-of select="'class'"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@type"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:copy>
                    <xsl:attribute name="type" select="$type"/>
                    <xsl:sequence select="imf:create-output-element('ep:name', $name)"/>
                    <xsl:sequence select="imf:create-output-element('ep:tech-name', imf:get-normalized-name($tech-name,'type-name'))"/>      
                    <xsl:sequence select="imf:create-output-element('ep:documentation', $doc,'',false(),false())"/>
                    <ep:seq>
                    <!--xsl:result-document href="{concat('file:/c:/temp/construct-',$name,'-',generate-id(),'.xml')}">
                        <xsl:copy-of select="$construct"/>
                    </xsl:result-document-->
                        <xsl:if test="@type='class'">
                            <xsl:sequence select="imf:create-debug-comment(concat('OAS01720, id: ',$id),$debugging)"/>
                            <xsl:apply-templates select="$construct//imvert:attributes/imvert:attribute"/>
                        </xsl:if>
                        <xsl:sequence select="imf:create-debug-comment(concat('OAS01740, id: ',$id),$debugging)"/>                   
                        <xsl:apply-templates select="ep:superconstruct" mode="as-content"/>
                        <xsl:sequence select="imf:create-debug-comment(concat('OAS01760, id: ',$id),$debugging)"/>
                        <xsl:apply-templates select="ep:construct[@type!='class']" mode="as-content"/>
                        <xsl:sequence select="imf:create-debug-comment(concat('OAS01780, id: ',$id),$debugging)"/>
                    </ep:seq>
                </xsl:copy>
            </xsl:when>
            <!-- if the ep:constructs is of 'complex-datatype' type its name differs from the one in the when above.
                 It's name isn't based on the attribute using the type since it is more generic and used by more than one ep:construct. --> 
            <xsl:when test="@type = 'complex-datatype'">
                <xsl:sequence select="imf:create-debug-comment(concat('OAS01850, id: ',$id),$debugging)"/>
                <xsl:variable name="type" select="@type"/>
                <xsl:variable name="complex-datatype-tech-name" select="$construct/imvert:class/imvert:name"/>
                <xsl:copy>
                    <xsl:attribute name="type" select="$type"/>
                    <xsl:sequence select="imf:create-output-element('ep:name', $construct/imvert:class/imvert:name/@original)"/>
                    <xsl:sequence select="imf:create-output-element('ep:tech-name', imf:get-normalized-name($complex-datatype-tech-name,'type-name'))"/>            
                    <xsl:sequence select="imf:create-output-element('ep:documentation', $doc,'',false(),false())"/>
                    <ep:seq>
                        <xsl:sequence select="imf:create-debug-comment(concat('OAS01900, id: ',$id),$debugging)"/>
                        <xsl:apply-templates select="$construct//imvert:attributes/imvert:attribute"/>
                        <xsl:sequence select="imf:create-debug-comment(concat('OAS01950, id: ',$id),$debugging)"/>                   
                        <xsl:apply-templates select="ep:superconstruct" mode="as-content"/>
                        
                        <!-- TODO: Nagaan of er in een complex-datatype type ep:construct geen associations voor kunnen komen.
                                   Indien dat wel het geval is dan moet hier ook een apply-templates komen op een ep:construct en moet ook het rough-messages stylesheets
                                   daar rekening mee houden. -->
                    </ep:seq>
                </xsl:copy>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <!-- All imvert:attribute elements found in the classes refered to are processed here. -->
    <xsl:template match="imvert:attribute">
        <xsl:variable name="name" select="imvert:name/@original" as="xs:string"/>
        <xsl:variable name="tech-name" select="imf:get-normalized-name(imvert:name, 'element-name')" as="xs:string"/>
        <xsl:variable name="doc">
            <xsl:if test="not(empty(imf:merge-documentation(.,'CFG-TV-DEFINITION')))">
                <ep:definition>
                    <xsl:sequence select="imf:merge-documentation(.,'CFG-TV-DEFINITION')"/>
                </ep:definition>
            </xsl:if>
            <xsl:if test="not(empty(imf:merge-documentation(.,'CFG-TV-DESCRIPTION')))">
                <ep:description>
                    <xsl:sequence select="imf:merge-documentation(.,'CFG-TV-DESCRIPTION')"/>
                </ep:description>
            </xsl:if>
            <xsl:if test="not(empty(imf:get-most-relevant-compiled-taggedvalue(., '##CFG-TV-PATTERN')))">
                <ep:pattern>
                    <ep:p>
                        <xsl:sequence select="imf:get-most-relevant-compiled-taggedvalue(., '##CFG-TV-PATTERN')"/>
                    </ep:p>
                </ep:pattern>
            </xsl:if>
        </xsl:variable>


        <xsl:variable name="suppliers" as="element(ep:suppliers)">
            <ep:suppliers>
                <xsl:copy-of select="imf:get-UGM-suppliers(.)"/>
            </ep:suppliers>
        </xsl:variable>
        <xsl:variable name="tvs" as="element(ep:tagged-values)">
            <ep:tagged-values>
                <xsl:copy-of select="imf:get-compiled-tagged-values(., true())"/>
            </ep:tagged-values>
        </xsl:variable>


        <xsl:choose>
            <!-- Attributes of complex datatype type are not resolved within this template but with one of the ep:construct templates since they are present
                 within the rough message structure. -->
            <xsl:when test="imvert:type-id and imvert:type-id = $packages//imvert:class[imvert:stereotype/@id = ('stereotype-name-complextype')]/imvert:id">
                <xsl:sequence select="imf:create-debug-comment(concat('OAS02000, id: ',imvert:id),$debugging)"/>
            </xsl:when>
            <!-- The content of ep:constructs based on attributes which refer to a tabelentiteit is determined by the imvert:attribute in that tabelentiteit class
                 which serves as a unique key. So it get all properties of that unique key. -->
            <xsl:when test="imvert:type-id and imvert:type-id = $packages//imvert:class[imvert:stereotype/@id = ('stereotype-name-referentielijst')]/imvert:id">
                <xsl:variable name="type-id" select="imvert:type-id"/>
                <xsl:variable name="tabelEntiteit">
                    <xsl:sequence select="$packages//imvert:class[imvert:stereotype/@id = ('stereotype-name-referentielijst') and imvert:id = $type-id]"/>
                </xsl:variable>
                <!--ep:construct type="attribute"-->
                <xsl:choose>
                    <xsl:when test="not($tabelEntiteit//imvert:attribute[imvert:is-id = 'true'])">
                        <xsl:variable name="msg"
                            select="concat('The &quot;tabelenitiet&quot; ',$tabelEntiteit/imvert:name,'does not have an attribute defined as an id.')"/>
                        <xsl:sequence select="imf:msg('WARNING', $msg)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <ep:construct>
                            <xsl:sequence select="imf:create-debug-comment(concat('OAS02050, id: ',imvert:id),$debugging)"/>
                            <xsl:sequence
                                select="imf:create-output-element('ep:name', $name)"/>
                            <xsl:sequence
                                select="imf:create-output-element('ep:tech-name', $tech-name)"/>
                            <xsl:sequence select="imf:create-output-element('ep:documentation', $doc,'',false(),false())"/>
                            <xsl:sequence select="imf:create-output-element('ep:min-occurs', imvert:min-occurs)"/>
                            <xsl:sequence select="imf:create-output-element('ep:max-occurs', imvert:max-occurs)"/>
                            <xsl:sequence select="imf:create-output-element('ep:data-type', $tabelEntiteit//imvert:attribute[imvert:is-id = 'true']/imvert:type-name)"/>   
                            
                            <xsl:variable name="max-length" select="$tabelEntiteit//imvert:attribute[imvert:is-id = 'true']/imvert:max-length"/>
                            <xsl:variable name="total-digits" select="$tabelEntiteit//imvert:attribute[imvert:is-id = 'true']/imvert:total-digits"/>
                            <xsl:variable name="fraction-digits" select="$tabelEntiteit//imvert:attribute[imvert:is-id = 'true']/imvert:fraction-digits"/>
                            <xsl:variable name="min-waarde" select="imf:get-tagged-value($tabelEntiteit//imvert:attribute[imvert:is-id = 'true'],'##CFG-TV-MINVALUEINCLUSIVE')"/>
                            <xsl:variable name="max-waarde" select="imf:get-tagged-value($tabelEntiteit//imvert:attribute[imvert:is-id = 'true'],'##CFG-TV-MAXVALUEINCLUSIVE')"/>
                            <xsl:variable name="min-length" select="xs:integer(imf:get-tagged-value($tabelEntiteit//imvert:attribute[imvert:is-id = 'true'],'##CFG-TV-MINLENGTH'))"/>
                            <xsl:variable name="patroon" select="$tabelEntiteit//imvert:attribute[imvert:is-id = 'true']/imvert:pattern"/>
                            
                            <xsl:sequence select="imf:create-output-element('ep:max-length', $max-length)"/>
                            <!--xsl:sequence select="imf:create-output-element('ep:total-digits', $total-digits)"/>
                    <xsl:sequence select="imf:create-output-element('ep:fraction-digits', $fraction-digits)"/-->
                            <xsl:sequence select="imf:create-output-element('ep:min-waarde', $min-waarde)"/>
                            <xsl:sequence select="imf:create-output-element('ep:max-waarde', $max-waarde)"/>
                            <!--xsl:sequence select="imf:create-output-element('ep:min-length', $min-length)"/-->
                            <xsl:sequence select="imf:create-output-element('ep:patroon', $patroon)"/>
                        </ep:construct>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- imvert:attribute having an imvert:type-id result in an ep:construct which refers to a global ep:construct. This is for example the case
                 when it's an attribute with a enumeration type. -->
            <xsl:when test="imvert:type-id">
                <!--ep:construct type="attribute"-->
                <ep:construct>
                    <xsl:sequence select="imf:create-debug-comment(concat('OAS02100, id: ',imvert:id),$debugging)"/>
                    <xsl:sequence
                        select="imf:create-output-element('ep:name', $name)"/>
                    <xsl:sequence
                        select="imf:create-output-element('ep:tech-name', $tech-name)"/>
                    <xsl:sequence select="imf:create-output-element('ep:documentation', $doc,'',false(),false())"/>
                    <xsl:sequence select="imf:create-output-element('ep:min-occurs', imvert:min-occurs)"/>
                    <xsl:sequence select="imf:create-output-element('ep:max-occurs', imvert:max-occurs)"/>
                    <xsl:sequence select="imf:create-output-element('ep:type-name', imf:get-normalized-name(imvert:type-name,'type-name'))"/>            
                </ep:construct>
            </xsl:when>
            <!-- In all other cases the imvert:attribute itself and its properties are processed. -->
            <xsl:otherwise>
                <!--ep:construct type="attribute"-->
                <ep:construct>
                    <xsl:sequence select="imf:create-debug-comment(concat('OAS02150, id: ',imvert:id),$debugging)"/>


                    <xsl:if test="$debugging">
                        <ep:suppliers>
                            <xsl:copy-of select="$suppliers"/>
                        </ep:suppliers>
                        <ep:tagged-values>
                            <xsl:copy-of select="$tvs"/>
                            <ep:found-tagged-values>
                                <xsl:sequence select="imf:create-output-element('ep:documentation', $doc,'',false(),false())"/>									
                            </ep:found-tagged-values>
                        </ep:tagged-values>
                    </xsl:if>


                    <xsl:sequence
                        select="imf:create-output-element('ep:name', $name)"/>
                    <xsl:sequence
                        select="imf:create-output-element('ep:tech-name', $tech-name)"/>
                    <xsl:sequence select="imf:create-output-element('ep:documentation', $doc,'',false(),false())"/>
                    <xsl:sequence select="imf:create-output-element('ep:min-occurs', imvert:min-occurs)"/>
                    <xsl:sequence select="imf:create-output-element('ep:max-occurs', imvert:max-occurs)"/>
                    <xsl:sequence select="imf:create-output-element('ep:data-type', imvert:type-name)"/>   

                    <xsl:variable name="max-length" select="imvert:max-length"/>
                    <xsl:variable name="total-digits" select="imvert:total-digits"/>
                    <xsl:variable name="fraction-digits" select="imvert:fraction-digits"/>
                    <xsl:variable name="min-waarde" select="imf:get-tagged-value(.,'##CFG-TV-MINVALUEINCLUSIVE')"/>
                    <xsl:variable name="max-waarde" select="imf:get-tagged-value(.,'##CFG-TV-MAXVALUEINCLUSIVE')"/>
                    <xsl:variable name="min-length" select="xs:integer(imf:get-tagged-value(.,'##CFG-TV-MINLENGTH'))"/>
                    <xsl:variable name="patroon" select="imvert:pattern"/>
                    
                    <xsl:sequence select="imf:create-output-element('ep:max-length', $max-length)"/>
                    <xsl:sequence select="imf:create-output-element('ep:length', $total-digits)"/>
                    <xsl:sequence select="imf:create-output-element('ep:fraction-digits', $fraction-digits)"/>
                    <xsl:sequence select="imf:create-output-element('ep:min-value', $min-waarde)"/>
                    <xsl:sequence select="imf:create-output-element('ep:max-value', $max-waarde)"/>
                    <xsl:sequence select="imf:create-output-element('ep:min-length', $min-length)"/>
                    <xsl:sequence select="imf:create-output-element('ep:patroon', $patroon)"/>
                </ep:construct>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Following template creates global ep:constructs for enumeration/ -->
    <xsl:template match="imvert:class" mode="mode-global-enumeration">
        <xsl:sequence select="imf:create-debug-comment('OAS02200',$debugging)"/>
        <xsl:variable name="compiled-name" select="imf:get-compiled-name(.)"/>
        
        <ep:construct>
            <xsl:sequence select="imf:create-output-element('ep:name', imf:capitalize($compiled-name))"/>
            <xsl:sequence select="imf:create-output-element('ep:tech-name', imf:capitalize($compiled-name))"/>
            <xsl:sequence select="imf:create-output-element('ep:data-type', 'scalar-string')"/>
            <xsl:apply-templates select="imvert:attributes/imvert:attribute" mode="mode-local-enum"/>
        </ep:construct>
    </xsl:template>

    <xsl:template match="imvert:attribute" mode="mode-local-enum">
        <xsl:sequence select="imf:create-debug-comment('OAS02300',$debugging)"/>
        
        <!-- STUB De naam van een enumeratie is die overgenomen uit SIM. Niet camelcase. Vooralsnog ook daar ophalen. -->
        
        <xsl:variable name="supplier" select="imf:get-trace-suppliers-for-construct(.,1)[@project='SIM'][1]"/>
        <xsl:variable name="construct" select="if ($supplier) then imf:get-trace-construct-by-supplier($supplier,$imvert-document) else ()"/>
        <xsl:variable name="SIM-name" select="($construct/imvert:name, imvert:name)[1]"/>
        
        <ep:enum><xsl:value-of select="$SIM-name"/></ep:enum>
        
    </xsl:template>

    <!-- This function merges all documentation from the highest layer up to the current layer. -->
    <xsl:function name="imf:merge-documentation">
        <xsl:param name="this"/>
        <xsl:param name="tv-id"/>
        
        
        <xsl:variable name="all-tv" select="imf:get-all-compiled-tagged-values($this,false())"/>
        <xsl:variable name="vals" select="$all-tv[@id = $tv-id]"/>
        <xsl:for-each select="$vals">
            <xsl:variable name="p" select="normalize-space(imf:get-clean-documentation-string(imf:get-tv-value.local(.)))"/>
            <xsl:if test="not($p = '')">
                <ep:p subpath="{imf:get-subpath(@project,@application,@nrelease)}">
                    <xsl:value-of select="$p"/>
                </ep:p>
            </xsl:if>
        </xsl:for-each>
    </xsl:function>
    
    <xsl:function name="imf:get-tv-value.local">
        <xsl:param name="tv-element" as="element(tv)?"/>
        <xsl:value-of select="if (normalize-space($tv-element/@original-value)) then $tv-element/@original-value else $tv-element/@value"/>
    </xsl:function>	

    <xsl:function name="imf:capitalize">
        <xsl:param name="name"/>
        <xsl:value-of select="concat(upper-case(substring($name,1,1)),substring($name,2))"/>
    </xsl:function>
    
    <xsl:function name="imf:get-stereotype">
        <xsl:param name="this"/>
        <xsl:sequence select="$this/imvert:stereotype/@id"/>
    </xsl:function>


    <xsl:function name="imf:get-compiled-name">
        <xsl:param name="this" as="element()"/>
        <xsl:variable name="type" select="local-name($this)"/>
        <xsl:variable name="stereotype" select="imf:get-stereotype($this)"/>
        <xsl:variable name="alias" select="$this/imvert:alias"/>
        <xsl:variable name="name-raw" select="$this/imvert:name"/>
        <xsl:variable name="name-form" select="replace(imf:strip-accents($name-raw),'[^\p{L}0-9.\-]+','_')"/>
        
        <xsl:variable name="name" select="$name-form"/>
        
        <xsl:choose>
            <xsl:when test="$type = 'class' and $stereotype = ('stereotype-name-composite')">
                <xsl:value-of select="concat(imf:capitalize($name),'Grp')"/>
            </xsl:when>
            <xsl:when test="$type = 'class' and $stereotype = ('stereotype-name-objecttype')">
                <xsl:value-of select="$alias"/>
            </xsl:when>
            <xsl:when test="$type = 'class' and $stereotype = ('stereotype-name-relatieklasse')">
                <xsl:value-of select="$alias"/>
            </xsl:when>
            <xsl:when test="$type = 'class' and $stereotype = ('stereotype-name-referentielijst')">
                <xsl:value-of select="$alias"/>
            </xsl:when>
            <xsl:when test="$type = 'class' and $stereotype = ('stereotype-name-complextype')">
                <xsl:value-of select="$name"/>
            </xsl:when>
            <xsl:when test="$type = 'class' and $stereotype = ('stereotype-name-enumeration')">
                <xsl:value-of select="$name"/>
            </xsl:when>
            <xsl:when test="$type = 'class' and $stereotype = ('stereotype-name-union')">
                <xsl:value-of select="$name"/>
            </xsl:when>
            <xsl:when test="$type = 'class' and $stereotype = ('stereotype-name-interface')">
                <!-- this must be an external -->
                <xsl:variable name="external-name" select="imf:get-external-type-name($this,true())"/>
                <xsl:value-of select="$external-name"/>
            </xsl:when>
            <xsl:when test="$type = 'attribute' and $stereotype = ('stereotype-name-attribute')">
                <xsl:value-of select="$name"/>
            </xsl:when>
            <xsl:when test="$type = 'attribute' and $stereotype = ('stereotype-name-referentie-element')">
                <xsl:value-of select="$name"/>
            </xsl:when>
            <xsl:when test="$type = 'attribute' and $stereotype = ('stereotype-name-data-element')">
                <xsl:value-of select="$name"/>
            </xsl:when>
            <xsl:when test="$type = 'attribute' and $stereotype = ('stereotype-name-enum')">
                <xsl:value-of select="$name"/>
            </xsl:when>
            <xsl:when test="$type = 'attribute' and $stereotype = ('stereotype-name-union-element')">
                <xsl:value-of select="imf:useable-attribute-name($name,$this)"/>
            </xsl:when>
            <xsl:when test="$type = 'association' and $stereotype = ('stereotype-name-relatiesoort') and normalize-space($alias)">
                <!-- if this relation occurs multiple times, add the alias of the target object -->
                <xsl:value-of select="$alias"/>
            </xsl:when>
            <xsl:when test="$type = 'association' and $this/imvert:aggregation = 'composite'">
                <xsl:value-of select="$name"/>
            </xsl:when>
            <xsl:when test="$type = 'association' and $stereotype = ('stereotype-name-relatiesoort')">
                <xsl:sequence select="imf:msg($this,'ERROR','No alias',())"/>
                <xsl:value-of select="lower-case($name)"/>
            </xsl:when>
            <xsl:when test="$type = 'association' and normalize-space($alias)"> <!-- composite -->
                <xsl:value-of select="$alias"/>
            </xsl:when>
            <xsl:when test="$type = 'association'">
                <xsl:sequence select="imf:msg($this,'ERROR','No alias',())"/>
                <xsl:value-of select="lower-case($name)"/>
            </xsl:when>
            <!-- TODO meer soorten namen uitwerken? -->
            <xsl:otherwise>
                <xsl:sequence select="imf:msg($this,'ERROR','Unknown type [1] with stereo [2]', ($type, string-join($stereotype,', ')))"/>
            </xsl:otherwise>
        </xsl:choose>      
    </xsl:function>

    <xsl:function name="imf:useable-attribute-name">
        <xsl:param name="name" as="xs:string"/>
        <xsl:param name="attribute" as="element(imvert:attribute)"/>
        <xsl:choose>
            <xsl:when test="empty($attribute/imvert:type-id) and exists($attribute/imvert:baretype) and count($all-simpletype-attributes[imvert:name = $attribute/imvert:name]) gt 1">
                <!--xx <xsl:message select="concat($attribute/imvert:name, ';', $attribute/@display-name)"/> xx-->
                <xsl:value-of select="concat($name,$attribute/../../imvert:alias)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$name"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="imf:get-external-type-name">
        <xsl:param name="attribute"/>
        <xsl:param name="as-type" as="xs:boolean"/>
        <!-- determine the name; hard koderen -->
        <xsl:for-each select="$attribute"> <!-- singleton -->
            <xsl:choose>
                <xsl:when test="imvert:type-package='Geography Markup Language 3'">
                    <xsl:variable name="type-suffix" select="if ($as-type) then 'Type' else ''"/>
                    <xsl:variable name="type-prefix">
                        <xsl:choose>
                            <xsl:when test="empty(imvert:conceptual-schema-type)">
                                <xsl:sequence select="imf:msg(.,'ERROR','No conceptual schema type specified',())"/>
                            </xsl:when>
                            <xsl:when test="imvert:conceptual-schema-type = 'GM_Point'">gml:Point</xsl:when>
                            <xsl:when test="imvert:conceptual-schema-type = 'GM_Curve'">gml:Curve</xsl:when>
                            <xsl:when test="imvert:conceptual-schema-type = 'GM_Surface'">gml:Surface</xsl:when>
                            <xsl:when test="imvert:conceptual-schema-type = 'GM_MultiPoint'">gml:MultiPoint</xsl:when>
                            <xsl:when test="imvert:conceptual-schema-type = 'GM_MultiSurface'">gml:MultiSurface</xsl:when>
                            <xsl:when test="imvert:conceptual-schema-type = 'GM_MultiCurve'">gml:MultiCurve</xsl:when>
                            <xsl:when test="imvert:conceptual-schema-type = 'GM_Geometry'">gml:Geometry</xsl:when>
                            <xsl:when test="imvert:conceptual-schema-type = 'GM_MultiGeometry'">gml:MultiGeometry</xsl:when>
                            <xsl:when test="imvert:conceptual-schema-type = 'GM_ArcString'">gml:ArcString</xsl:when>
                            <xsl:when test="imvert:conceptual-schema-type = 'GM_LineString'">gml:LineString</xsl:when>
                            <xsl:when test="imvert:conceptual-schema-type = 'GM_Polygon'">gml:Polygon</xsl:when>
                            <xsl:when test="imvert:conceptual-schema-type = 'GM_Object'">gml:GeometryProperty</xsl:when><!-- see http://www.geonovum.nl/onderwerpen/geography-markup-language-gml/documenten/handreiking-geometrie-model-en-gml-10 -->
                            <xsl:when test="imvert:conceptual-schema-type = 'GM_Primitive'">gml:Primitive</xsl:when>
                            <xsl:when test="imvert:conceptual-schema-type = 'GM_Position'">gml:Position</xsl:when>
                            <xsl:when test="imvert:conceptual-schema-type = 'GM_PointArray'">gml:PointArray</xsl:when>
                            <xsl:when test="imvert:conceptual-schema-type = 'GM_Solid'">gml:Solid</xsl:when>
                            <xsl:when test="imvert:conceptual-schema-type = 'GM_OrientableCurve'">gml:OrientableCurve</xsl:when>
                            <xsl:when test="imvert:conceptual-schema-type = 'GM_OrientableSurface'">gml:OrientableSurface</xsl:when>
                            <xsl:when test="imvert:conceptual-schema-type = 'GM_CompositePoint'">gml:CompositePoint</xsl:when>
                            <xsl:when test="imvert:conceptual-schema-type = 'GM_MultiSolid'">gml:MultiSolid</xsl:when>
                            <xsl:otherwise>
                                <xsl:sequence select="imf:msg(.,'ERROR','Cannot handle the [1] type [2]', (imvert:type-package,imvert:conceptual-schema-type))"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:value-of select="concat($type-prefix,$type-suffix)"/>
                </xsl:when>
                <xsl:when test="empty(imvert:type-package)">
                    <!-- TODO -->
                </xsl:when>
                <xsl:when test="contains(imvert:baretype,'GM_')">
                    <xsl:variable name="type-suffix" select="if ($as-type) then 'Type' else ''"/>
                    <xsl:variable name="type-prefix">
                        <xsl:choose>
                            <xsl:when test="imvert:baretype = 'GM_Point'">gml:Point</xsl:when>
                            <xsl:when test="imvert:baretype = 'GM_Curve'">gml:Curve</xsl:when>
                            <xsl:when test="imvert:baretype = 'GM_Surface'">gml:Surface</xsl:when>
                            <xsl:when test="imvert:baretype = 'GM_MultiPoint'">gml:MultiPoint</xsl:when>
                            <xsl:when test="imvert:baretype = 'GM_MultiSurface'">gml:MultiSurface</xsl:when>
                            <xsl:when test="imvert:baretype = 'GM_MultiCurve'">gml:MultiCurve</xsl:when>
                            <xsl:when test="imvert:baretype = 'GM_Geometry'">gml:Geometry</xsl:when>
                            <xsl:when test="imvert:baretype = 'GM_MultiGeometry'">gml:MultiGeometry</xsl:when>
                            <xsl:when test="imvert:baretype = 'GM_ArcString'">gml:ArcString</xsl:when>
                            <xsl:when test="imvert:baretype = 'GM_LineString'">gml:LineString</xsl:when>
                            <xsl:when test="imvert:baretype = 'GM_Polygon'">gml:Polygon</xsl:when>
                            <xsl:when test="imvert:baretype = 'GM_Object'">gml:GeometryProperty</xsl:when><!-- see http://www.geonovum.nl/onderwerpen/geography-markup-language-gml/documenten/handreiking-geometrie-model-en-gml-10 -->
                            <xsl:when test="imvert:baretype = 'GM_Primitive'">gml:Primitive</xsl:when>
                            <xsl:when test="imvert:baretype = 'GM_Position'">gml:Position</xsl:when>
                            <xsl:when test="imvert:baretype = 'GM_PointArray'">gml:PointArray</xsl:when>
                            <xsl:when test="imvert:baretype = 'GM_Solid'">gml:Solid</xsl:when>
                            <xsl:when test="imvert:baretype = 'GM_OrientableCurve'">gml:OrientableCurve</xsl:when>
                            <xsl:when test="imvert:baretype = 'GM_OrientableSurface'">gml:OrientableSurface</xsl:when>
                            <xsl:when test="imvert:baretype = 'GM_CompositePoint'">gml:CompositePoint</xsl:when>
                            <xsl:when test="imvert:baretype = 'GM_MultiSolid'">gml:MultiSolid</xsl:when>
                            <xsl:otherwise>
                                <xsl:sequence select="imf:msg(.,'ERROR','Cannot handle the [1] type [2]', (imvert:type-package,imvert:baretype))"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:value-of select="concat($type-prefix,$type-suffix)"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- geen andere externe packages bekend -->
                    <xsl:sequence select="imf:msg(.,'ERROR','Cannot handle the external package [1]', imvert:type-package)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        
    </xsl:function>
    
</xsl:stylesheet>