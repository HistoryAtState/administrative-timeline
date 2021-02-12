<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt3"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:sqf="http://www.schematron-quickfix.com/validator/process">
    <title>Administrative Timeline TEI encoding checks</title>
    <ns uri="http://www.tei-c.org/ns/1.0" prefix="tei"/>
    <ns uri="http://www.functx.com" prefix="functx"/>
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
    <!-- in lieu of a proper ODD, ensure content can be transformed to & from Airtable flavored markdown... -->
    <pattern id="airtable-flavored-markdown-checks">
        <rule context="tei:div[not(@type)]//*">
            <assert test="./name() = ('head', 'date', 'p', 'hi', 'ref')">This <value-of
                    select="./name()"/> element is not allowed.</assert>
        </rule>
    </pattern>
    <pattern id="chronological-ordering-checks">
        <rule context="tei:div[tei:head/tei:date and preceding::tei:div/tei:head/tei:date]">
            <let name="current-entry-date"
                value="tei:head/tei:date/(@when, @from, @notBefore)[1] cast as xs:date"/>
            <let name="previous-entry-date"
                value="preceding::tei:div[1]/tei:head/tei:date/(@when, @from, @notBefore)[1] cast as xs:date"/>
            <assert test="$current-entry-date ge $previous-entry-date"><value-of
                    select="format-date($current-entry-date, '[MNn] [D], [Y]')"/> predates the
                previous entry, <value-of
                    select="format-date($previous-entry-date, '[MNn] [D], [Y]')"/>. Please keep the
                entries in chronological order.</assert>
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
    <pattern id="date-alignment-checks">
        <rule context="tei:date[@when]">
            <assert test="normalize-space(.) = format-date(@when cast as xs:date, '[MNn] [D], [Y]')"
            />
        </rule>
        <rule context="tei:date[@from and @to]">
            <let name="from" value="
                    (@from cast as xs:date) ! map {
                        'date': .,
                        'year': year-from-date(.),
                        'month': month-from-date(.),
                        'day': day-from-date(.)
                    }"/>
            <let name="to" value="
                    (@to cast as xs:date) ! map {
                        'date': .,
                        'year': year-from-date(.),
                        'month': month-from-date(.),
                        'day': day-from-date(.)
                    }"/>
            <let name="expected-regex" value="
                    (: Month1 Day1, Year1–Month2 Day2, Year2:)
                    if ($from?year ne $to?year) then
                        format-date($from?date, '[MNn] [D], [Y]') || '–' || format-date($to?date, '[MNn] [D], [Y]')
                    else (: Month1 Day1–Month2 Day2, Year:)
                        if ($from?month ne $to?month) then
                            format-date($from?date, '[MNn] [D]') || '–' || format-date($to?date, '[MNn] [D], [Y]')
                        else (: Month1 Day1(‘–’ or ‘ and ’)Day2, Year :)
                            format-date($from?date, '[MNn] [D]') || '( and |–)' || format-date($to?date, '[D], [Y]')"/>
            <assert test="matches(normalize-space(.), '^' || $expected-regex || '$')">Expected
                from-to date to be formatted as <value-of select="$expected-regex"/>.</assert>
        </rule>
        <rule context="tei:date[@notBefore and @notAfter]">
            <let name="notBefore" value="
                    (@notBefore cast as xs:date) ! map {
                        'date': .,
                        'year': year-from-date(.),
                        'month': month-from-date(.),
                        'day': day-from-date(.),
                        'days-in-month': functx:days-in-month(.)
                    }"/>
            <let name="notAfter" value="
                    (@notAfter cast as xs:date) ! map {
                        'date': .,
                        'year': year-from-date(.),
                        'month': month-from-date(.),
                        'day': day-from-date(.),
                        'days-in-month': functx:days-in-month(.)
                    }"/>
            <let name="expected-regex" value="
                    (: Year :)
                    if ($notBefore?year eq $notAfter?year and $notBefore?month eq 1 and $notAfter?month eq 12 and $notBefore?day eq 1 and $notAfter?day eq 31) then
                        format-date($notBefore?date, '[Y]')
                    else (: Month Year :)
                        if ($notBefore?year eq $notAfter?year and $notBefore?month eq $notAfter?month and $notBefore?day eq 1 and $notAfter?day eq $notAfter?days-in-month) then
                            format-date($notBefore?date, '[MNn] [Y]')
                        else (: Month1–Month2, Year :)
                            if ($notBefore?year eq $notAfter?year and $notBefore?month ne $notAfter?month and $notBefore?day eq 1 and $notAfter?day eq $notAfter?days-in-month) then
                                format-date($notBefore?date, '[MNn]') || '–' || format-date($notAfter?date, '[MNn], [Y]')
                            else (: Year1–Year2 :)
                                if ($notBefore?year ne $notAfter?year and $notBefore?month eq 1 and $notAfter?month eq 12 and $notBefore?day eq 1 and $notAfter?day eq 31) then
                                    format-date($notBefore?date, '[Y]') || '–' || format-date($notAfter?date, '[Y]')
                                else (: Month1 Year1–Month2 Year2 :)
                                    if ($notBefore?year ne $notAfter?year and $notBefore?month ne $notAfter?month and $notBefore?day eq 1 and $notAfter?day eq $notAfter?days-in-month) then
                                        format-date($notBefore?date, '[MNn] [Y]') || '–' || format-date($notAfter?date, '[MNn] [Y]')
                                    else
                                        'Sorry! Unrecognized uncertain date range pattern. Let Joe know!'"/>
            <assert role="warning" test="matches(normalize-space(.), '^' || $expected-regex || '$')"
                >Expected “<value-of select="."/>” to be formatted as “<value-of
                    select="$expected-regex"/>”, according to uncertain date range rules.</assert>
        </rule>
    </pattern>
    <!-- http://www.xsltfunctions.com/xsl/functx_days-in-month.html -->
    <xsl:function name="functx:days-in-month" as="xs:integer?" xmlns:functx="http://www.functx.com">
        <xsl:param name="date" as="xs:anyAtomicType?"/>
        <xsl:sequence select="
                if (month-from-date(xs:date($date)) = 2 and functx:is-leap-year($date)) then
                    29
                else
                    (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)[month-from-date(xs:date($date))]"
        />
    </xsl:function>
    <xsl:function name="functx:is-leap-year" as="xs:boolean" xmlns:functx="http://www.functx.com">
        <xsl:param name="date" as="xs:anyAtomicType?"/>
        <xsl:sequence select="
                for $year in xs:integer(substring(string($date), 1, 4))
                return
                    ($year mod 4 = 0 and $year mod 100 != 0) or $year mod 400 = 0"/>
    </xsl:function>
</schema>
