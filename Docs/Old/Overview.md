# Overview
(Spitballing the pitch to see if it holds weight)

## Alchemy
Alchemy is a Swift web framework created with the developer experience in mind.
1. Easy to Learn & Understand (`Learning.md`)
- Amazing Documentation.
- Excellent, in depth tutorials. On both Alchemy & Server development (primary audience will be iOS devs).
- What questions might people have and how can we ensure they know exactly where to go to answer these as soon as possible?
2. Delightful APIs (`Features.md`)
- Expressive APIs with a focus on writing safe, readable, simple code.
- Branded APIs that are fun to write & have a natural english flow to them.
- "Swifty" APIs should have a Swift spin on them and use "cool new stuff" (but only when applicable!). Also leverage type safety, error handling, generics, etc (interesting article here https://www.swiftbysundell.com/articles/what-makes-code-swifty/) 
- Writing code should be fun.
- Encourage best database and SWE practices; e.g. unique identifiers on DB models, mocking & testing for DI, etc 
3. Tooling. A focus on tools to help the developer deploy, monitor & understand their server. (`Tooling.md`)
- The tools should be a joy to interact with. Simplicity, attractive UI, elegant CLI, etc.
- Tools that help the developer...
a) create & release faster
b) understand & monitor better
c) learn & build knowledge

## Monetization
Monetization inventivizes us to make the best framework possible for the user so lots of people use and upsell to...
1. Tutorials / Casts
2. Tooling
???

## Why Swift?
At the end of the day, atm there's not a super compelling argument for swift on server for anyone but iOS devs. Sure it's safe and fast but so are the more established go & rust. I think presenting this with a focus on the benegit for iOS devs is the way to go.
1. Elegant,powerful, fast language. (not-ish unique to swift)
2. Static & an emphasis on writing safe code. (not-ish unique to swift)
3. A language many people are already familiar with. (unique to swift for those people)
4. Allows for shared code between client & server. (unique to swift... RN sux)

## How does Alchemy uniquely leverage Swift to provide a web framework experience that's amazing?
1. Focus on error handling & safety. Leverage optionals, throwing and static typing.
2. Elegant APIs (functional, closures, encourage writing safe code).
3. Leverage a shared client / server language.
- How can the user write less code?
- How can the user improve type safety between client & server?
- How can the user use similar patterns on both client & server to reduce context switching?

## Cons
1. Swift is only well supported on mac & ubuntu (dunno what the roadmap for other distros/windows is)
2. Swift server area is very new (but apple now has a group of devs doing solid swift server tooling that is creating some good stuff)
3. Package manager can be janky (but getting very close imo)
