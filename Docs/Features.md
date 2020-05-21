# Framework Features
(Nothing is ranked by importance yet, just spitballing; not all of these by any means necessary for launch)

## API Design
Each API should be... (ignoring docs)
1. Simple to understand at first glance. Easy for noobs to pick up.
2. Swifty (safe, leverage typing, error handling, leverage language features, etc)
3. Readable and "fun" (i.e. branding, naming, etc)
4. Encourage best practices

## Core Framework

### Some brainstorming of APIs
Very WIP brainstorming in `Sources/Alchemy/*`, some more than others.  
Note: APIs compile but aren't at all implemented (basically just doing interface exploration)
- Routing (`/Routing`, example in `/Example/ExampleApplication`)
- Environments (prod, stage, testing, local, etc) (`/Applicaton/Environment.swift`)
- HTTP Client (`/HTTPClient`)
- ORM (with relationships and eager loading) (`/ORM`)
- Auth (`/Authentication`, example in `/Example/ExampleApplication`)
- Middleware (`/Routing`, example in `/Example/ExampleApplication`)

### No brainstorming done yet
- Cache
- Job Queues
- CORS
- Centralized bug reporting
- Mail / notifications
- Render in template language 
(^ can this be a typed templating dsl leveraging function builders that's a .swift file? 
No clue why vapor has their own & why it isn't typed...? https://docs.vapor.codes/3.0/leaf/getting-started/ 
something like https://github.com/pointfreeco/swift-html also looks good
also, haven't looked in depth at all but this seemed cool & might be relevant https://github.com/JohnSundell/Publish)

## Associated 1st party libs
To help capitalize on the benefits of shared code between client & server there can be some libs that are applicable to both

Spitballing:
- Dependency Injection (`/Services/Services.swift` & tiny example in `/Example/ExampleApplication`)
- Swifty IDLs (WIP here https://github.com/joshuawright11/SwiftAPI can put some more complicated examples up later). Basic idea: consume these interfaces on client or server, also have functionality for producing & validating them on the server. 
- Out there, but wondering if there is any benefit to sharing ORM syntax for an easy SQLite db on iOS.
- 
