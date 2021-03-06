<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ext="http://www.imvertor.org/xsl/extensions"
    xmlns:imvert="http://www.imvertor.org/schema/system"
    xmlns:imf="http://www.imvertor.org/xsl/functions"
    
    exclude-result-prefixes="#all"
    version="2.0">
    
    <!-- INSPIRE -->
    
    <xsl:variable name="inspire-notes-default-section-title" select="$configuration-notesrules-file/notes-rule/@default"/>
    <xsl:variable name="inspire-notes-parts" select="distinct-values($configuration-notesrules-file/notes-rule/section/label/@title)"/>
    <xsl:variable name="inspire-notes-parts-subpattern" select="string-join(for $part in $inspire-notes-parts return concat('(',$part,')'),'|')"/> <!-- (DEFINITION)|(SOURCE)|(EXAMPLE)|(URI)|(NOTE) -->
    <xsl:variable name="inspire-notes-parts-subpattern-count" select="count($inspire-notes-parts)"/>
    
    <xsl:function name="imf:inspire-notes-sections" as="element(wrap)">
        <xsl:param name="text"/>
        <!-- several kinds of dashes. https://www.cs.tut.fi/~jkorpela/dashes.html -->
        <xsl:variable name="grp" select="'[&#45;&#8208;&#8209;&#8210;&#8211;&#8212;&#8213;&#8722;]{2}'"/>
        <xsl:variable name="proc-text" select="if (matches($text,concat('^\s*',$grp))) then $text else concat('-- ',$inspire-notes-default-section-title,' --&#10;', $text)"/>
        <wrap>
            <xsl:analyze-string select="$proc-text" regex="{$grp}\s*(.*?)\s*{$grp}">
                <xsl:matching-substring>
                    <sec>
                        <xsl:value-of select="regex-group(1)"/>
                    </sec>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:variable name="t" select="normalize-space(.)"/>
                    <xsl:if test="$t">
                        <bdy>
                            <xsl:sequence select="imf:inspire-notes-parts(.)"/>
                        </bdy>
                    </xsl:if>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </wrap>
    </xsl:function>
    
    <xsl:function name="imf:inspire-notes-parts" as="element()*">
        <xsl:param name="text"/>
        <xsl:choose>
            <xsl:when test="normalize-space($inspire-notes-parts-subpattern)">
                <!-- labels have been defined -->
                <xsl:analyze-string select="$text" regex="({$inspire-notes-parts-subpattern})\s+(.*?)\n\s*?(\n|$)" flags="s">
                    <xsl:matching-substring>
                        <typ>
                            <xsl:value-of select="regex-group(1)"/>
                        </typ>
                        <val>
                            <xsl:value-of select="regex-group($inspire-notes-parts-subpattern-count + 2)"/>
                        </val>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <txt>
                            <xsl:value-of select="."/>
                        </txt>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <xsl:otherwise>
                <!-- no labels have been defined -->
                <txt>
                    <xsl:value-of select="$text"/>
                </txt>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="imf:inspire-notes" as="element(section)*">
        <xsl:param name="text"/>
        <xsl:variable name="seq" select="imf:inspire-notes-sections($text)"/>
        <xsl:apply-templates select="$seq/sec"  mode="inspire-notes"/>
    </xsl:function>
    
    <xsl:function name="imf:inspire-notes-lines" as="element(line)*">
        <xsl:param name="text"/>
        <xsl:analyze-string select="$text" regex="^\n*(.+?)\n*$" flags="s">
            <xsl:matching-substring>
                <xsl:for-each select="tokenize(regex-group(1),'\n')">
                    <line>
                        <xsl:value-of select="."/>
                    </line>
                </xsl:for-each>            </xsl:matching-substring>        
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:template match="sec" mode="inspire-notes">
        <xsl:variable name="sec-content" as="element()*">
            <xsl:apply-templates select="following-sibling::*[1][self::bdy]/(typ | txt)" mode="inspire-notes"/>
        </xsl:variable>
        <xsl:if test="exists($sec-content)">
            <section>
                <title>
                    <xsl:value-of select="."/>
                </title>
                <body>
                    <xsl:sequence select="$sec-content"/>
                </body>
            </section>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="typ" mode="inspire-notes">
        <label type="{.}">
            <xsl:apply-templates select="following-sibling::*[1][self::val]" mode="inspire-notes"/>
        </label>
    </xsl:template>
    
    <xsl:template match="val" mode="inspire-notes">
        <xsl:value-of select="."/>
    </xsl:template>
    
    <xsl:template match="txt" mode="inspire-notes">
        <xsl:if test="normalize-space(.)">
            <text>
                <xsl:sequence select="imf:inspire-notes-lines(.)"/>
            </text>
        </xsl:if>
    </xsl:template>
    
    <!-- == END OF INSPIRE == -->
    
</xsl:stylesheet>