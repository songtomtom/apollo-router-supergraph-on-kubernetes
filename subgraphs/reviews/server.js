import {readFileSync} from 'node:fs';
import {ApolloServer} from '@apollo/server';
import {startStandaloneServer} from '@apollo/server/standalone';
import {buildSubgraphSchema} from '@apollo/subgraph';
import {parse} from 'graphql';

const typeDefs = parse(readFileSync('./schema.graphql', 'utf8'));

const reviews = [
    {id: 'r1', productId: '1', body: '키감이 좋다', rating: 5},
    {id: 'r2', productId: '1', body: '소음이 있다', rating: 3},
    {id: 'r3', productId: '2', body: '가볍다', rating: 4}
];

const byProduct = id => reviews.filter(r => r.productId === id);

const resolvers = {
    Query: {reviews: () => reviews},
    Product: {
        reviews: p => byProduct(p.id),
        averageRating: p => {
            const rs = byProduct(p.id);
            return rs.length ? rs.reduce((s, r) => s + r.rating, 0) / rs.length : null;
        }
    }
};

const server = new ApolloServer({schema: buildSubgraphSchema([{typeDefs, resolvers}])});
const {url} = await startStandaloneServer(server, {listen: {port: Number(process.env.PORT ?? 4001), host: '0.0.0.0'}});
console.log(`reviews subgraph ready at ${url}`);
