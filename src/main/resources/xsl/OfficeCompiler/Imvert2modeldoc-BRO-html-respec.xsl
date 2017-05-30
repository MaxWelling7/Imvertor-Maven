<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    
    xmlns:imvert="http://www.imvertor.org/schema/system"
    xmlns:ext="http://www.imvertor.org/xsl/extensions"
    xmlns:imf="http://www.imvertor.org/xsl/functions"
    
    exclude-result-prefixes="#all" 
    version="2.0">
    
    <xsl:import href="../common/Imvert-common.xsl"/>
    
    <xsl:output method="html" indent="yes" omit-xml-declaration="yes"/>
    
    <!-- 
        create a Respec HTML representation of the section structure 
    -->
    
    <xsl:template match="/book">
        <h2>Catalogus</h2>
        <p class="ednote" title="Over deze catalogus">
            Deze catalogus is automatisch samengesteld op basis van het UML model 
            "<xsl:value-of select="@name"/>" door <xsl:value-of select="@version"/> op <xsl:value-of select="imf:format-dateTime(@date)"/>.
           <br/>
            Wanneer je technische fouten of onvolkomenheden aantreft, geef dit dan door aan <i>arjan.loeffen at armatiek.nl</i> en geef de code 
            <i><xsl:value-of select="imf:get-config-string('appinfo','office-documentation-filename')"/></i> door. 
            Voor inhoudelijke fouten neem contact op met het modellenteam.
        </p>
        <xsl:apply-templates select="section" mode="domain"/>
    </xsl:template>
    
    <xsl:template match="section" mode="domain">
        <xsl:apply-templates select="section" mode="detail"/>
    </xsl:template>
    
    <xsl:template match="section" mode="detail">
        <xsl:variable name="id" select="@id"/>
        <xsl:choose>
            <xsl:when test="@type = 'DETAILS'">
                <xsl:apply-templates mode="#current"/>
            </xsl:when>
            <xsl:when test="starts-with(@type,'DETAILS-')">
                <xsl:apply-templates mode="#current"/>
            </xsl:when>
            <xsl:when test="@type = 'EXPLANATION'">
                <div class="subheader">
                    <xsl:value-of select="imf:translate-i3n('EXPLANATION',$language-model,())"/>
                </div>
                <xsl:apply-templates select="content/part/item" mode="#current"/>
            </xsl:when>
            <xsl:when test="@type = 'SHORT-ATTRIBUTES'">
                <div class="subheader">
                    <xsl:value-of select="imf:translate-i3n('SHORT-ATTRIBUTES',$language-model,())"/>
                </div>
                <xsl:apply-templates mode="detail"/>
            </xsl:when>
            <xsl:when test="@type = 'SHORT-ASSOCIATIONS'">
                <div class="subheader">
                    <xsl:value-of select="imf:translate-i3n('SHORT-ASSOCIATIONS',$language-model,())"/>
                </div>
                <xsl:apply-templates mode="detail"/>
            </xsl:when>
            <xsl:when test="@type = 'DETAIL-COMPOSITE-ATTRIBUTE'">
                <xsl:variable name="level" select="count(ancestor::section) + 1"/>
                <xsl:variable name="composer" select="content/part[@type = 'COMPOSER']/item[1]"/>
                <a class="anchor" name="{$id}"/>
                <div>
                    <xsl:element name="{concat('h',$level)}">
                        <xsl:value-of select="imf:translate-i3n('ATTRIBUTE',$language-model,())"/>
                        <xsl:value-of select="' '"/>
                        <xsl:value-of select="@name"/>
                        <xsl:value-of select="' '"/>
                        <xsl:value-of select="' '"/>
                        <xsl:value-of select="$composer"/>
                    </xsl:element>
                    <xsl:apply-templates mode="detail"/>
                </div>
            </xsl:when>
            <xsl:when test="@type = 'DETAIL-COMPOSITE-ASSOCIATION'">
                <xsl:variable name="level" select="count(ancestor::section)"/>
                <xsl:variable name="composer" select="content/part[@type = 'COMPOSER']/item[1]"/>
                <a class="anchor" name="{$id}"/>
                <div>
                    <xsl:element name="{concat('h',$level)}">
                        <xsl:value-of select="imf:translate-i3n('ASSOCIATION',$language-model,())"/>
                        <xsl:value-of select="' '"/>
                        <xsl:value-of select="@name"/>
                        <xsl:value-of select="' '"/>
                        <xsl:value-of select="imf:translate-i3n('OF-COMPOSITION',$language-model,())"/>
                        <xsl:value-of select="' '"/>
                        <xsl:value-of select="$composer"/>
                    </xsl:element>
                    <xsl:apply-templates mode="detail"/>
                </div>
            </xsl:when>
            <xsl:when test="starts-with(@type,'OVERVIEW-')">
                <xsl:variable name="level" select="count(ancestor::section)"/>
                <a class="anchor" name="{$id}"/>
                <section>
                    <xsl:element name="{concat('h',$level)}">
                        <xsl:value-of select="imf:translate-i3n(@type,$language-model,())"/>
                        <xsl:value-of select="' '"/>
                        <xsl:value-of select="@name"/>
                    </xsl:element>
                    <xsl:apply-templates mode="detail"/>
                </section>
            </xsl:when> 
            <xsl:when test="@type = ('OBJECTTYPE')"> <!-- objecttypes are in TOC -->
                <xsl:variable name="level" select="count(ancestor::section)"/>
                <a class="anchor" name="{$id}"/>
                <section>
                    <xsl:element name="{concat('h',$level)}">
                        <xsl:value-of select="imf:translate-i3n(@type,$language-model,())"/>
                        <xsl:value-of select="' '"/>
                        <xsl:value-of select="@name"/>
                    </xsl:element>
                    <xsl:apply-templates mode="detail"/>
                </section>
            </xsl:when>
            <xsl:when test="starts-with(@type,'DETAIL-')">
                <xsl:variable name="level" select="count(ancestor::section)"/>
                <a class="anchor" name="{$id}"/>
                <div>
                    <xsl:element name="{concat('h',$level)}">
                        <xsl:value-of select="imf:translate-i3n(@type,$language-model,())"/>
                        <xsl:value-of select="' '"/>
                        <a href="#{@id-global}">
                            <xsl:value-of select="../@name"/>
                        </a>
                        <xsl:value-of select="' '"/>
                        <xsl:value-of select="@name"/>
                    </xsl:element>
                    <xsl:apply-templates mode="detail"/>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="level" select="count(ancestor::section)"/>
                <a class="anchor" name="{$id}"/>
                <div>
                    <xsl:element name="{concat('h',$level)}">
                        <xsl:value-of select="imf:translate-i3n(@type,$language-model,())"/>
                        <xsl:value-of select="' '"/>
                        <xsl:value-of select="@name"/>
                    </xsl:element>
                    <xsl:apply-templates mode="detail"/>
                </div>
            </xsl:otherwise>
            
        </xsl:choose>
       
    </xsl:template>
    
    <xsl:template match="content" mode="detail">
        <table>
            <tbody>
                <xsl:if test="exists(itemtype)">
                    <tr>
                        <xsl:apply-templates select="itemtype" mode="#current"/>
                    </tr>
                </xsl:if>
                <xsl:apply-templates select="part" mode="#current"/>
            </tbody>
        </table>
    </xsl:template>
    
    <xsl:template match="itemtype" mode="detail">
        <td>
            <i>
                <xsl:value-of select="if (@type) then imf:translate-i3n(@type,$language-model,()) else ''"/>
            </i>
        </td>
    </xsl:template>
    
    <xsl:template match="part" mode="detail">
        <xsl:variable name="items" select="count(item)"/>
        <xsl:variable name="type" select="ancestor::section/@type"/>
        <tr>
            <xsl:choose>
                <xsl:when test="@type = 'COMPOSER' and $type='DETAIL-COMPOSITE-ATTRIBUTE'">
                    <!-- skip, do not show in detail listings -->
                </xsl:when>
                <xsl:when test="@type = 'COMPOSER'">
                    <td width="5%">&#160;</td>
                    <td width="25%">
                        <xsl:apply-templates select="item[1]" mode="#current"/>
                        <xsl:text>:</xsl:text>
                    </td>
                    <td width="50%">
                        <xsl:apply-templates select="item[2]" mode="#current"/>
                    </td>
                    <td width="10%">
                        <xsl:apply-templates select="item[3]" mode="#current"/>
                    </td>
                    <td width="10%">
                        <xsl:apply-templates select="item[4]" mode="#current"/>
                    </td>
                </xsl:when>
                <xsl:when test="$type = 'EXPLANATION'">
                    <td width="5%">&#160;</td>
                    <td width="95%">
                        <xsl:apply-templates select="item" mode="#current"/>
                    </td>
                </xsl:when>
                <xsl:when test="$type = 'SHORT-ASSOCIATIONS'">
                    <td width="5%">&#160;</td>
                    <td width="45%">
                        <xsl:if test="@type = 'COMPOSED'">- </xsl:if>
                        <xsl:apply-templates select="item[1]" mode="#current"/>
                        <xsl:if test="@type = 'COMPOSER'">:</xsl:if>
                    </td>
                    <td width="50%">
                        <xsl:apply-templates select="item[2]" mode="#current"/>
                    </td>
                </xsl:when>
                <xsl:when test="$type = 'SHORT-ATTRIBUTES'">
                    <td width="5%">&#160;</td>
                    <td width="25%">
                        <xsl:if test="@type = 'COMPOSED'">- </xsl:if>
                        <xsl:apply-templates select="item[1]" mode="#current"/>
                        <xsl:if test="@type = 'COMPOSER'">:</xsl:if>
                    </td>
                    <td width="50%">
                        <xsl:apply-templates select="item[2]" mode="#current"/>
                    </td>
                    <td width="10%">
                        <xsl:apply-templates select="item[3]" mode="#current"/>
                    </td>
                    <td width="10%">
                        <xsl:apply-templates select="item[4]" mode="#current"/>
                    </td>
                </xsl:when>
                <xsl:when test="$type = 'DETAIL-ENUMERATION' and $items = 2"> 
                    <td width="40%">
                        <b>
                            <xsl:apply-templates select="item[1]" mode="#current"/>
                        </b>
                    </td>
                    <td width="60%">
                        <xsl:apply-templates select="item[2]" mode="#current"/>
                    </td>
                </xsl:when>
                <xsl:when test="$type = 'DETAIL-ENUMERATION' and $items = 3"> 
                    <td width="10%">
                        <xsl:apply-templates select="item[1]" mode="#current"/>
                    </td>
                    <td width="30%">
                        <xsl:apply-templates select="item[2]" mode="#current"/>
                    </td>
                    <td width="60%">
                        <xsl:apply-templates select="item[3]" mode="#current"/>
                    </td>
                </xsl:when>
               <?x
                <xsl:when test="$items = 2 and not(normalize-space(item[2]))"> <!-- DEFAULT TWO COLUMNS; remove when second column has no text -->
                   <!-- remove -->
                </xsl:when>
               
               x?>
                <xsl:when test="$items = 2"> <!-- DEFAULT TWO COLUMNS -->
                    <td width="30%">
                        <b>
                            <xsl:apply-templates select="item[1]" mode="#current"/>
                        </b>
                    </td>
                    <td width="70%">
                        <xsl:apply-templates select="item[2]" mode="#current"/>
                    </td>
                </xsl:when>
                
                <xsl:otherwise>
                    <xsl:message select="concat('ONBEKEND: ', string-join($type,', ') , ' - ',$items)"></xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </tr>
    </xsl:template>
    
    <!--<xsl:template match="item/item" mode="detail">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>-->
    
    <xsl:template match="item" mode="#all">
        <xsl:choose>
            <xsl:when test="exists(@idref)">
                <a class="link" href="#{@idref}">
                    <xsl:apply-templates mode="#current"/>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="#current"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="text()">
        <xsl:value-of select="."/>
    </xsl:template>
    
    <xsl:function name="imf:create-nonheader">
        <xsl:param name="headertext"/>
        <table>
            <tbody>
                <tr>
                    <td width="30%">
                        <b>
                            <xsl:sequence select="$headertext"/>
                        </b>
                    </td>
                </tr>
            </tbody>
        </table>
    </xsl:function>
    
</xsl:stylesheet>