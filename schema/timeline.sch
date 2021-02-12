<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
    xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
    xmlns:tei="http://www.tei-c.org/ns/1.0">
    <title>Administrative Timeline TEI encoding checks</title>
    <ns uri="http://www.tei-c.org/ns/1.0" prefix="tei"/>
    <pattern id="div-head-checks">
        <rule context="tei:div[@type = 'section']">
            <assert test="not(tei:head/tei:date)">Sections heads should not have date
                elements</assert>
        </rule>
        <rule context="tei:div[not(@type)]">
            <assert
                test="tei:head/tei:date/(@when or (@from and @to) or (@notBefore and @notAfter))"
                >Missing required attributes in entry head/date: a @when, or a @from and @to, or a
                @notBefore and @notAfter.</assert>
        </rule>
    </pattern>
    <pattern id="chronological-ordering-checks">
        <rule context="tei:div[tei:head/tei:date and preceding::tei:div/tei:head/tei:date]">
            <let name="current-entry-date" value="tei:head/tei:date/(@when, @from, @notBefore)[1]"/>
            <let name="previous-entry-date"
                value="preceding::tei:div[1]/tei:head/tei:date/(@when, @from, @notBefore)[1]"/>
            <assert test="$current-entry-date ge $previous-entry-date">The date of this entry,
                    <value-of select="$current-entry-date"/>, is before the previous entry's date,
                    <value-of select="$previous-entry-date"/>. Please place the entries in
                chronological order.</assert>
        </rule>
    </pattern>
    <pattern id="date-attribute-validity-checks">
        <rule context="@when">
            <assert test=". castable as xs:date">This @when attribute, <value-of select="."/>, must
                be a complete date, YYYY-MM-DD. Alternatively, consider a @from-@to for a certain
                date range, or @notBefore-@notAfter for an uncertain date range.</assert>
        </rule>
        <rule context="@from">
            <assert test=". castable as xs:date">This @from attribute, <value-of select="."/>, must
                be a complete date, YYYY-MM-DD. Alternatively, consider @notBefore-@notAfter for an
                uncertain date range.</assert>
        </rule>
        <rule context="@to">
            <assert test=". castable as xs:date and . gt ../@from">This @to attribute, <value-of
                    select="."/>, must be a complete date, YYYY-MM-DD and fall chronologically after
                its corresponding @from, <value-of select="../@from"/>. Alternatively, consider
                @notBefore-@notAfter for an uncertain date range.</assert>
        </rule>
        <rule context="@notBefore">
            <assert test=". castable as xs:date">This @notBefore attribute, <value-of select="."/>,
                must be a complete date, YYYY-MM-DD. Alternatively, consider @from-@to for an
                certain date range.</assert>
        </rule>
        <rule context="@notAfter">
            <assert test=". castable as xs:date and . gt ../@notBefore">This @notAfter attribute,
                    <value-of select="."/>, must be a complete date, YYYY-MM-DD and fall
                chronologically after its corresponding @notBefore, <value-of select="../@notBefore"
                />. Alternatively, consider @from-@to for an certain date range.</assert>
        </rule>
    </pattern>
</schema>
