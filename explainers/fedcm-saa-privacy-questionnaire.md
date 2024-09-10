# Security / Privacy Questionnaire for FedCM as a trust signal for the Storage Access API

> 01.  What information does this feature expose,
>      and for what purposes?

This feature exposes no additional information to websites. It allows successful grants of SAA calls when a prior FedCM permission has been allowed by the user. Both APIs allow for cross-site identification, but are gated on user permission.

> 2.  Do features in your specification expose the minimum amount of information
>      necessary to implement the intended functionality?

Yes, no additional information is exposed.

> 5.  Do the features in your specification expose personal information,
>      personally-identifiable information (PII), or information derived from
>      either?

Not in itself, though again this feature integrates two existing APIs that are frequently used to transmit such information across sites (gated on user permission).

> 7.  How do the features in your specification deal with sensitive information?

It doesn't in itself.

> 8.  Does data exposed by your specification carry related but distinct
>      information that may not be obvious to users?

No

> 10.  Do the features in your specification introduce state
>      that persists across browsing sessions?

No, it uses existing permission state from FedCM grants.

> 12.  Do the features in your specification expose information about the
>      underlying platform to origins?

No

> 14.  Does this specification allow an origin to send data to the underlying
>      platform?

No

> 16.  Do features in this specification enable access to device sensors?

No

> 17.  Do features in this specification enable new script execution/loading
>      mechanisms?

No

> 18.  Do features in this specification allow an origin to access other devices?

No

> 19.  Do features in this specification allow an origin some measure of control over
>      a user agent's native UI?

No

> 20.  What temporary identifiers do the features in this specification create or
>      expose to the web?

None it itself.

> 21.  How does this specification distinguish between behavior in first-party and
>      third-party contexts?

It follows the existing behavior of SAA and FedCM in 1P / 3P contexts

> 22.  How do the features in this specification work in the context of a browser’s
>      Private Browsing or Incognito mode?

See https://github.com/privacycg/storage-access/blob/main/tag-security-questionnaire.md for how SAA handles private / incognito mode.

> 24.  Does this specification have both "Security Considerations" and "Privacy
>      Considerations" sections?

Yes

> 26.  Do features in your specification enable origins to downgrade default
>      security protections?

Not beyond how SAA already allows for downgrading the security protections afforded by third-party cookie blocking.

> 28.  What happens when a document that uses your feature is kept alive in BFCache
>      (instead of getting destroyed) after navigation, and potentially gets reused
>      on future navigations back to the document?

This feature uses long-lived FedCM grants and as such is intended to be usable in future documents or future navigations to the same document.
 
> 30.  What happens when a document that uses your feature gets disconnected?

This feature simply adds an additional trust parameter for allowing SAA grants, so this shouldn't be a consideration.

> 32.  Does your feature allow sites to learn about the users use of assistive technology?

No

> 34.  What should this questionnaire have asked?
