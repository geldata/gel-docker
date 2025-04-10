import argparse
import gel
from aiohttp import web


async def read(request):
    name = request.match_info['name']
    value = await request.app['gel'].query_single("""
        SELECT (
            SELECT Counter { visits } FILTER .name = <str>$name
        ).visits ?? 0
    """, name=name)
    return web.Response(text=f"Current counter value: {value}")


async def increment(request):
    name = request.match_info['name']
    value = await request.app['gel'].query_single("""
        SELECT (
            INSERT Counter { name := <str>$name, visits := 1 }
            UNLESS CONFLICT ON .name ELSE (
                UPDATE Counter SET { visits := Counter.visits + 1 }
            )
        ).visits
    """, name=name)
    return web.Response(text=f"Updated counter value: {value}")


async def app(options):
    app = web.Application()
    app.add_routes([web.get('/read/{name}', read)])
    app.add_routes([web.get('/increment/{name}', increment)])
    app['gel'] = gel.create_async_client()
    return app


def main():

    ap = argparse.ArgumentParser()
    ap.add_argument('-p', '--port', default=80)
    options = ap.parse_args()

    web.run_app(app(options), port=options.port, host='0.0.0.0')
