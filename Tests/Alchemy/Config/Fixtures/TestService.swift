import Alchemy

struct TestService: Service, Configurable {
    struct Config {
        let foo: String
    }

    static var config = Config(foo: "baz")
    static var foo: String = "bar"
    
    let bar: String
    
    static func configure(using config: Config) {
        foo = config.foo
    }
}

extension ServiceIdentifier where Service == TestService {
    static var foo: TestService.Identifier { "foo" }
}
