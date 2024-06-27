# FedCM as a trust signal for the Storage Access API

## Authors

*   [Johann Hofmann](https://github.com/johannhof)
*   [Chris Fredrickson](https://github.com/cfredric)
*   [Yi Gu](https://github.com/yi-gu)

## Table of Contents

- [Introduction](#introduction)
- [Goals](#goals)
- [Non-goals](#non-goals)
- [Motivation](#motivation)
  - [Example Use cases](#example-use-cases)
- [API Details](#api-details)
- [Considered alternatives](#considered-alternatives)
- [Privacy Considerations](#privacy-considerations)
- [Security Considerations](#security-considerations)

## Introduction

When a user consents to using their identity with a 3rd party Identity Provider (IdP) on a Relying Party (RP), many IdPs require third-party cookies to function correctly and securely. Currently, while these IdPs might prefer to use [FedCM](https://github.com/fedidcg/FedCM) for an overall better user experience, they would not be able to for lack of cookie access and would have to show the more generic [Storage Access API](https://github.com/privacycg/storage-access) (SAA) prompts instead.

This proposal aims to satisfy that requirement in a private and secure manner by updating the Storage Access API (SAA) permission checks to not only accept the permission grant that is given by a storage access prompt, but also the permission grant that is given by a FedCM prompt.

A key property of this mechanism is limiting the grant to cases explicitly allowed by the RP via the FedCM permissions policy, enforcing a per-frame control for the RP and preventing passive surveillance by the IdP beyond the capabilities that FedCM already grants, as outlined in the [Privacy Considerations](#privacy-considerations).

Where there are no negative implications for user privacy and security, we propose following the more flexible double-keyed per-site grant scope of SAA vs. the triple-keyed per-origin scope of FedCM as described in the [API Details](#api-details), to maximize developer utility.

## Goals


*   Improve the user experience by enabling cookie-based identity / sign-in use cases to use FedCM.
*   Allow developers to avoid explicit token handling and the usage of HttpOnly and Secure attributes via cookies, to reduce susceptibility to cookie theft attacks.
*   Securely mediate access to cookies via FedCM through explicit Storage Access opt-in.


## Non-Goals
*   Change the privacy and security model behind a FedCM grant. Accepting the prompt should have the same privacy and security implications to a user as before. Specifically, any continued access to cross-site data for an IdP after a FedCM grant should require [active collaboration from an RP](#privacy-considerations).
*   Deprecate Storage Access API prompts. This proposal adds an additional means of utilizing the SAA, we do not propose removing other ways of setting storage access permissions, such as the UI shown by browsers as part of a “traditional” storage access request. It’s important to preserve this shared prompt for web interop and we encourage developers with cross-site cookie access needs to fall back to it where possible.

## Motivation

[FedCM](https://fedidcg.github.io/FedCM/) is an API that mediates federated user identity flows through the application of (ideally) well-understood, purpose-driven user interfaces. Using the `navigator.credentials` API, it exposes a high-entropy user identifier (token) from an IdP to an RP.

This kind of token based authentication/authorization is commonly used in federated identity flows, which FedCM intends to address. Other login schemes, particularly for Single-Sign-On (SSO), rely on the presence of (cross-site) cookies as explained in the examples below.

These kind of flows can currently be solved by the Storage Access API, which mediates permission for documents to access cross-site cookies. However, as SAA lacks additional context on the nature of the request for cross-site cookie access, its UI in browsers tends to be very generic and unintuitive. It’s also primarily designed to solve use cases for authenticated embeds, which makes it difficult to fit seamlessly onto SSO flows (without sacrificing some of the anti-abuse mechanics of SAA such as the prior user gesture requirement).

Due to its arguably much more intuitive user experience for mediating user identity, FedCM would be a good fit to cover these login-oriented use cases instead. To do this, it needs to be compatible with identity flows that require cookies to work. This is where a well-designed integration with SAA can help, by providing secure access to cross-site cookies based on FedCM grants as an additional trust signal.


### Example Use Cases

These are examples we’ve found in our work with partners on resolving breakage from the deprecation of third-party cookies, but it’s important to note that this list does not exhaustively describe the utility a flexible integration such as the one proposed here would bring to developers.


#### SSO through SAML in subresources

Consider dashboard.example, an enterprise application which provides a centralized integration of various custom views from third-party analytics vendors. It does this by displaying a number of cross-site iframes (called embed.example in the below graphic) that contain relevant business information for the user, and as such need to be gated on some user authentication. Authenticating the user to these individual iframes is done seamlessly via an IDP (idp.example), which the user initially logs into in a top-level context.

![image](https://github.com/explainers-by-googlers/storage-access-for-fedcm/assets/2622601/6aa831f2-5a4d-472b-87d7-e702c3f8e59e)


During the initial login flow, the IDP stores the user identity in a SameSite=None cookie and can now function as an SSO provider, commonly via brief redirects to idp.example which returns a SAML response (or similar) to the originally requested site. This works well in a top-level context, where idp.example has access to its first-party cookies, but third-party cookie blocking prevents it from working in embedded contexts.

This is an issue for dashboard.example, as each of its embeds needs to authenticate through a redirect to idp.example.

![image](https://github.com/explainers-by-googlers/storage-access-for-fedcm/assets/2622601/129517f1-cf31-4bca-8c9b-3a383dfca2c1)

With this proposal, dashboard.example could initially authenticate with idp.example via FedCM. Then, assuming the user grants this request, idp.example would be allowed to use SAA (possibly via [storage access headers](https://github.com/cfredric/storage-access-headers)) to enable its identity flow.

![image](https://github.com/explainers-by-googlers/storage-access-for-fedcm/assets/2622601/a81017fa-8599-4cfb-8905-9b3aaca5004a)

Switching to a cookie-less flow would have a number of drawbacks for idp.example in this case, notably the loss of cookie-specific security mechanics such as HttpOnly, the departure from established authentication patterns and the need to update third-party software that integrates with their services.


#### Iframe-based token refresh

For access control reasons, some IdPs want to avoid exposing long-lived and/or permissive tokens to its RPs through FedCM credentials. Instead, the IdP maintains an iframe embedded in the RP page, which periodically refreshes tokens and transmits them to the RP for usage as API tokens, encryption keys, etc.

![image](https://github.com/explainers-by-googlers/storage-access-for-fedcm/assets/2622601/3aa13dbf-8132-4ae0-b37c-43eb2799c8cc)


However, in order to perform this refresh, the IdP still needs to retain access to some longer lasting authentication token. This is typically done through the use of third-party cookies, which have excellent security properties as they’re accessible to the embedded IdP but not readable by its embedder or any (injected) scripts on the page.


## API Details

It’s important to note that we are not proposing any new web API surface, but instead a behavior change for the Storage Access API to consider FedCM grants. As such, the code examples might not reveal a lot of information about the desired effect of this proposal.


### Current FedCM / SAA functionality

Today, using FedCM, RPs can call FedCM to establish a persistent cross-site connection between themselves and specific IDPs.

```javascript
// In RP top-level document, where RP and IDP are cross-site:

// Ensure FedCM permission has been granted.
const cred = await navigator.credentials.get({
  identity: {
    providers: [{
      // normal IDP config, elided here.
    }],
  },
  mediation: 'optional', // default mediation mode
});
```

On initial use, this will prompt the user for permission via sign-in prompt mediated by the browser. The RP will use the FedCM API to sign-in the user (if needed), which creates the "connection" between the RP and IDP in the `connected accounts set` internally. This connection is keyed by the RP origin (the top-level origin), the IDP origin, the origin of the embedder when used in an iframe, and the account identifier.

As a result, cross-site credentials are returned and future invocations of `navigator.credentials.get() `under the same set of keys will not require browser mediation / user permission.

At this point, many IDPs have a need for access to 3rd party cookies, which, from a privacy perspective, would not exceed the capabilities already granted to them through the ability to exchange high-entropy credentials, but presents greater flexibility, security and a more powerful API.

To do this at the moment, they would have to invoke `document.requestStorageAccess()` which requires a new user gesture and spawns _another_ user permission prompt (they just accepted the FedCM prompt!)


### SAA Autogrants

Instead of showing this additional prompt, we propose that `document.requestStorageAccess() `take into consideration the `connected accounts set` that contains information about which RPs and IDPs are allowed to exchange cross-site information and considers it equivalent to the presence of a [storage-access](https://privacycg.github.io/storage-access/#permissiondef-storage-access) permission. When an RP/IDP pair has been approved for access to cross-site credentials, taking into account FedCM concepts such as [prevent silent access](https://w3c.github.io/webappsec-credential-management/#origin-prevent-silent-access-flag), it is also allowed storage access.

This comes without additional user activation or prior top-level user interaction requirements as it is treated like a granted permission (which seems most accurate given that the user has in fact interacted with a permission prompt from a FedCM IDP).

**Note that the automatic grant will not lead to a new storage-access permission being created.** FedCM grants work slightly differently (see below) and have different lifetimes, making it hard to convert them directly to storage-access permissions. It’s also undesirable for the user (agent) to maintain two separate permissions that grant a similar capability.

Instead, the `document.requestStorageAccess()`  call would set the environment’s [has storage access](https://privacycg.github.io/storage-access/#environment-has-storage-access) flag to true (i.e. [processing the FedCM grant as a permission state](https://privacycg.github.io/storage-access/#the-document-object:~:text=Let-,process%20permission%20state,-be%20an%20algorithm)), granting the iframe document access to cross-site cookies.

```javascript
// In RP top-level document, where RP and IDP are cross-site:

// Ensure FedCM permission has been granted.
const cred = await navigator.credentials.get({
  identity: {
    providers: [{
      // normal IDP config, elided here.
    }],
  },
  mediation: 'optional',
});

// In an embedded IDP iframe:

// No user gesture is needed to call this, and the call will be auto-granted.
await document.requestStorageAccess();
// This returns “true”.
const hasAccess = await document.hasStorageAccess();
```

This same check may be performed by proposed SAA extensions such as [requestStorageAccessFor](https://github.com/privacycg/requestStorageAccessFor) and [Storage Access Headers](https://github.com/cfredric/storage-access-headers) to enable additional flexibility for web developers.


### Dealing with scope differences

One complication to this idea is the fact that FedCM is scoped by origin, while SAA grants are scoped to site. FedCM also [differs in its permission keying](https://fedidcg.github.io/FedCM/#issue-d2fd6198) (which is to be specified). While storage-access permissions are keyed by (top-level, embed), FedCM grants are keyed by (top-level, embedder (RP), IDP).

This decision makes sense for FedCM as the tokens it mediates are directly returned to the caller of `navigator.credentials.get()`, and as such should be same-origin restricted by default. Additionally, merely double-keying by (RP, IDP) would allow an attacker iframe embedded in rp.example extract information about an adjacent idp.example using FedCM.

This restriction is not needed for SAA, as the information it mediates comes from cookies, where cross-subdomain sharing is an opt-in feature (via the Domain attribute), or [other storage types](https://github.com/arichiv/saa-non-cookie-storage/) which are already same-origin by default. This means that any same-site cross-origin sibling of the site calling FedCM will only have access to its own storage or explicitly registrable domain-scoped cookies.

There are still attacks (such as CSRF and click-jacking) and cross-site leaks which try to take advantage of this credentialed state without directly reading it. SAA, through its explicit opt-in mechanisms, puts embed developers at a much lower risk of being exposed to such an attack.

Although there is ostensibly little privacy or security benefit as shown above, with this proposal, we make it possible for the FedCM and SAA integration to honor the stricter scope of FedCM. Put differently, `document.requestStorageAccess() `auto-grants could be restricted to contexts in which RP and IDP are same-origin to their entries in the `connected accounts set`.

```javascript
// In top-level rp.example:

// Ensure FedCM permission has been granted.
const credential = await navigator.credentials.get({
  identity: {
    providers: [{
      configURL: "https://accounts.idp.example/manifest.json",
      clientId: "123",
    }]
  }
});

// In an embedded accounts.idp.example iframe, this call will automatically grant.
await document.requestStorageAccess();


// In an embedded idp.example iframe, should this automatically grant as well?
await document.requestStorageAccess();
```

The result of that choice would be that users could encounter situations where an embedded call to `document.requestStorageAccess()`is not automatically granted despite a FedCM grant being present for a (top-level site, embed site) pair (and the user having seen and accepted the FedCM prompt).

Overall, there seem to be 3 different options to pursue:



1. (Preferred) Grant storage-access with a wider scope than FedCM, by extracting the corresponding (top-level site, embedded site) pair from the FedCM grant.

This gives the greatest amount of developer flexibility and incurs no additional privacy risks (given that (partitioned) cookies can already be site scoped) and little security risk as explained above.



2. Expose additional parameters for RP and IDP to control the scope of storage access.

This would require changes in the FedCM API and increase overall complexity for developers. It also wouldn’t effectively protect the origin boundary given that any developer with a need to increase the scope to site could easily opt into it.



3. Simply match the scope of the FedCM grant and fall back to default SAA processing of a request (usually show a prompt) when it does not match.

This preserves the original FedCM scope, but could lead to additional SAA prompts showing in some cases. Another drawback is the developer-facing inconsistency of different storage access grants and the need to manage different types of storage access grants.

In the end, option 3 could prevent developers from building useful cross-site integrations and/or force them to show an SAA prompt with the same sites that the user just consented to via FedCM, which seems like a jarring user experience (or not use FedCM at all). Hence, we recommend option 1.


### Interaction with Permissions Policy

As explained in a lot of detail in the [Privacy Considerations](#privacy-considerations), an important property of this proposal is that it does not regress on the existing privacy guarantees of the FedCM API. One such guarantee is that the RP stays in control over when an IdP can access cross-site information via tokens through calling navigator.credentials.get(). This happens via the ["identity-credentials-get" Permissions Policy](https://fedidcg.github.io/FedCM/#permissions-policy-integration), which requires an opt-in by the RP.

To restrict storage access to only succeed when an IdP would be otherwise able to access cross-site credentials via navigator.credentials.get(), we propose that **both** the "identity-credentials-get" permission policy and the "storage-access" permission policy will be considered by the storage access integration.

This would require iframes which intend to use SAA with FedCM to have the `allow="identity-credentials-get"` attribute and **not** have an `allow="storage-access` none” (or similar) attribute.

As a side effect, this also gives RPs the ability to explicitly disallow IdPs from using Storage Access, though we haven’t identified a use case for this. 


## Considered Alternatives

* **Have FedCM set a new storage-access permission upon user grant.**
    As an alternative approach, upon successful grant, FedCM could simply set a new storage-access permission scoped to the respective (top-level site, embedded site) pair (i.e. RP and IDP). We discarded this idea as it has a few drawbacks:

  * Creating two simultaneous permissions / grants for a similar capability. This seems confusing for the user.
  * Relatedly, developers would now have to manage the permission for SAA, including different permission expiry from the FedCM grant.
  * This would be necessarily tied to the (broader) SAA permission scope.
  * This would be much harder to regulate via the “identity-credentials-get” permissions policy.
* **Modify requestStorageAccess to accept a <code>credential</code> object, and auto-grant SAA permission if the credential contains appropriate metadata.**
    This was an initial idea to ensure storage access it strictly tied to the availability of an identity credential. It seems unnecessarily complicated, given that the current proposal is able to enact the same scope without this measure.

## Privacy Considerations

### RP Control over IDP Storage Access

For both FedCM and the Storage Access API, their primary consideration for user privacy is the ability to link the user identity between two sites. In the case of FedCM, this happens through sharing a high-entropy identifier, with Storage Access API, shared identity can be established through the re-introduction of cross-site cookies for the embedded 3rd party (the IDP).

Both APIs are built for this purpose, and as such come with their own mechanisms (in most cases, prompts), to ensure sufficient user consent.

Does that mean that both exhibit the same risks to the user when one or more parties in the process are participating in cross-site tracking? It depends on the threat model we use.

A commonly applied threat model posits that both sharing a high-entropy identifier between two sites A and B, and permanent access to cross-site cookies for site B under A, is equivalent, because we assume possible coordination between A and B. When both parties are cooperating, a single high-entropy identifier can be used to establish a communication channel to transfer any amount of information between both parties, at any time (until the user clears all browser state for one of the parties, ignoring fingerprinting).

However, if we apply a different threat model and assume that some RPs may choose to not cooperate with an IDP to enable cross-site recognition, then they can use FedCM with a single call to navigator.credentials.get(), which will only connect the RP to the IDP a single time, and is thus more private than the permanent ability to make credentialed requests to a cross-site resource. The RP could then even continue to embed iframes from the IdP as long as the ”identity-credentials-get” permissions policy is not set on those.

There are still a few practical concerns with this idea:

*   In practice, IDPs usually coerce or enforce cooperation, e.g. by providing their own first-party scripts to run on a given RP.
*   The existence of partitioned state (e.g. CHIPS) or access to first-party state allows embedded 3Ps to sustain one-time identifiers indefinitely.

Nonetheless, we propose restricting an IDP’s default access to instances where an RP allows this [through use of the Permissions Policy API](#interaction-with-permissions-policy). This requires explicit RP collaboration for continued access to cross-site state.

This particularly helps protect against attacks where a large IDP may run additional embedded widgets (a social comment widget, an embedded maps widget, etc.) and would be able to use these to passively track users long after FedCM credentials were passed.


### Consistent user experience

User agents should make FedCM grants and Storage Access permissions behave consistently, reflecting their similar capabilities, and ensure users understand the difference and similarities between the two.

There are existing inconsistencies to deal with. In Chrome, the `connections `in the `connected accounts set` do not expire, while the `storage-access` permission expires after 30 days of disuse. This means that a user who grants FedCM permission is now granting perpetual access to unpartitioned cookies, whereas a user who grants storage access directly is only granting access for 30 days. Chrome currently also clears FedCM grants for sites when the user clears site data, but not Storage Access permissions. As user agents we should strive to reduce these inconsistencies where possible.

Given that FedCM mediates a high-entropy token already, this does not change the privacy properties of this proposal, but is noteworthy nonetheless.

## Security Considerations
As [previously discussed in the context of the Storage Access API](https://docs.google.com/document/d/1AsrETl-7XvnZNbG81Zy9BcZfKbqACQYBSrjM3VsIpjY/edit#heading=h.vb3ujl8dnk4q), opening up access to cross-site cookies when those cookies are otherwise blocked by default, comes with additional challenges for website security.

This proposal does not substantially change the security considerations that already apply to the Storage Access API or FedCM. However, for the proposed integration with requestStorageAccessFor, it’s important to consider the ability for the RP to attack the IDP using [attacks on credentialed cross-site resources that aren't fully mitigated through CORS](https://github.com/privacycg/requestStorageAccessFor/issues/30). The recent [storage access headers](https://github.com/cfredric/storage-access-headers) proposal provides a better alternative that mitigates these attacks and as such the rSAFor integration should be considered with additional scrutiny and may not end up being necessary.
