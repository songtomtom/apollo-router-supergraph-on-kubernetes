import {readFileSync} from 'node:fs';
import {ApolloServer} from '@apollo/server';
import {startStandaloneServer} from '@apollo/server/standalone';
import {buildSubgraphSchema} from '@apollo/subgraph';
import {parse} from 'graphql';

const typeDefs = parse(readFileSync('./schema.graphql', 'utf8'));

const products = [
    {id: '1', name: '키보드', price: 89000},
    {id: '2', name: '마우스', price: 45000},
    {id: '3', name: '모니터 암', price: 120000}
];

const resolvers = {
    Query: {
        products: () => products,
        product: (_, {id}) => products.find(p => p.id === id) ?? null
    },
    Product: {
        // 다른 서브그래프가 Product 엔티티를 참조할 때 id로 되찾는다
        __resolveReference: ref => products.find(p => p.id === ref.id) ?? null
    }
};

const server = new ApolloServer({schema: buildSubgraphSchema([{typeDefs, resolvers}])});
const {url} = await startStandaloneServer(server, {listen: {port: Number(process.env.PORT ?? 4001), host: '0.0.0.0'}});
console.log(`products subgraph ready at ${url}`);
