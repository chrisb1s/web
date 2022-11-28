import { put, call, takeEvery } from 'redux-saga/effects';
import { getCatalog } from '@lib/api/wanda';

import {
  setCatalogLoading,
  setCatalogData,
  setCatalogError,
} from '@state/catalogNew';

export function* updateCatalog() {
  yield put(setCatalogLoading());
  try {
    const { data: data } = yield call(getCatalog);
    yield put(setCatalogData({ data: data.items }));
  } catch (error) {
    yield put(setCatalogError({ error: error.message }));
  }
}

export function* watchCatalogUpdateNew() {
  yield takeEvery('UPDATE_CATALOG_NEW', updateCatalog);
}